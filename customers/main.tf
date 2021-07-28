data "aws_ecs_task_definition" "existing" {
  task_definition = local.task_definition_family
}

data "aws_ecs_container_definition" "existing" {
  container_name  = local.container_name
  task_definition = local.task_definition_family
}

resource "aws_ecs_task_definition" "this" {
  family = local.task_definition_family
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  task_role_arn      = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  proxy_configuration {
    container_name = "envoy"
    type           = "APPMESH"
    properties = {
      AppPorts         = local.container_port
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = data.aws_ecs_container_definition.existing.image
      essential = true
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Development"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        secretOptions : null
        options = {
          awslogs-group         = "/ecs/service-customers"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name  = "envoy",
      image = local.envoy_image
      environment = [
        {
          name  = "APPMESH_VIRTUAL_NODE_NAME"
          value = "mesh/${data.terraform_remote_state.ecs.outputs.appmesh_name}/virtualNode/${local.service_name}-node"
        },
        {
          name  = "ENABLE_ENVOY_XRAY_TRACING"
          value = "1"
        },
        {
          name  = "ENVOY_LOG_LEVEL"
          value = "info"
        }
      ]
      healthCheck = {
        retries = 3
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ]
        timeout     = 2
        interval    = 5
        startPeriod = 10
      }
      user = "1337"
      logConfiguration = {
        logDriver = "awslogs"
        secretOptions : null
        options = {
          awslogs-group         = "/ecs/service-customers"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name  = "xray-daemon"
      image = local.xray_image
      portMappings = [
        {
          hostPort      = 2000
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        secretOptions : null
        options = {
          awslogs-group         = "/ecs/service-customers"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_security_group" "app_security_group" {
  name        = "${local.service_name}-SG"
  description = "Security group for customer api to communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.service_name}-SG"
  }
}

resource "aws_ecs_service" "service" {
  name            = local.service_name
  cluster         = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition = "${aws_ecs_task_definition.this.family}:${max(aws_ecs_task_definition.this.revision, data.aws_ecs_task_definition.existing.revision)}"
  desired_count   = 1

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_application_subnets
    security_groups  = [aws_security_group.app_security_group.id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = local.container_name
  }
}

resource "aws_service_discovery_service" "this" {
  name = local.service_name

  dns_config {
    namespace_id = data.terraform_remote_state.ecs.outputs.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}