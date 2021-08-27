data "aws_secretsmanager_secret_version" "platform" {
  secret_id = "platform/shared"
}

locals {
  platform_creds   = jsondecode(data.aws_secretsmanager_secret_version.platform.secret_string)
  loki_url         = "https://${local.platform_creds.grafana_userid}:${local.platform_creds.grafana_apikey}@logs-prod-us-central1.grafana.net/loki/api/v1/push"
  loki_remove_keys = "container_id,ecs_task_arn"
  loki_label_keys  = "container_name,ecs_task_definition,source,ecs_cluster"
  loki_labels      = "{ecs_service=\"${local.service_name}\", env=\"${local.env}\"}"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.service_name}"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${local.service_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

resource "aws_service_discovery_service" "envoy_proxy" {
  name = "virtual-gateway.${data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_name}"

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

resource "aws_appmesh_virtual_gateway" "this" {
  name      = local.virtual_gateway_name
  mesh_name = data.terraform_remote_state.ecs.outputs.appmesh_name

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }

      health_check {
        port                = 80
        protocol            = "http"
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }
  }
}

data "aws_ecs_task_definition" "virtual_gateway" {
  task_definition = aws_ecs_task_definition.virtual_gateway.family
}

resource "aws_ecs_task_definition" "virtual_gateway" {
  family = "virtual-gateway"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = data.terraform_remote_state.ecs.outputs.default_task_execution_role_arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = jsonencode([
    {
      name  = "xray-daemon"
      image = var.xray_image
      portMappings = [
        {
          containerPort = 2000
          hostPort      = 2000
          protocol      = "udp"
        }
      ],
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "loki",
          Url        = local.loki_url
          Labels     = local.loki_labels
          RemoveKeys = local.loki_remove_keys
          LabelKeys  = local.loki_label_keys
          LineFormat = "key_value"
        }
      }
    },
    {
      name      = "envoy"
      image     = var.envoy_image
      essential = true
      environment = [
        {
          name  = "APPMESH_VIRTUAL_NODE_NAME",
          value = "mesh/${data.terraform_remote_state.ecs.outputs.appmesh_name}/virtualGateway/${local.virtual_gateway_name}"
        },
        {
          name  = "ENABLE_ENVOY_XRAY_TRACING",
          value = "1"
        },
        {
          name : "ENVOY_LOG_LEVEL",
          value : "info"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
        {
          containerPort = 9901
          hostPort      = 9901
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        retries     = 3
        timeout     = 2
        interval    = 5
        startPeriod = 60
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ]
      },
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "loki",
          Url        = local.loki_url
          Labels     = local.loki_labels
          RemoveKeys = local.loki_remove_keys
          LabelKeys  = local.loki_label_keys
          LineFormat = "key_value"
        }
      }
    },
    {
      essential = true,
      image     = var.fluent_bit_loki_image,
      name      = "log_router",
      firelensConfiguration : {
        type = "fluentbit",
        options : {
          enable-ecs-log-metadata = "true"
        }
      },
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group         = "/ecs/${local.service_name}",
          awslogs-region        = var.aws_region,
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "firelens"
        }
      },
      memoryReservation : 50
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                               = local.service_name
  cluster                            = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  task_definition                    = "${aws_ecs_task_definition.virtual_gateway.family}:${max(aws_ecs_task_definition.virtual_gateway.revision, data.aws_ecs_task_definition.virtual_gateway.revision)}"
  desired_count                      = var.virtual_gateway.desired_count
  deployment_maximum_percent         = var.virtual_gateway.max_percent
  deployment_minimum_healthy_percent = var.virtual_gateway.min_percent

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_application_subnets
    security_groups  = [aws_security_group.virtual_gateway.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.ecs.outputs.ecs_cluster_nlb_default_group_arn
    container_name   = "envoy"
    container_port   = 80
  }

  service_registries {
    registry_arn = aws_service_discovery_service.envoy_proxy.arn
  }

  health_check_grace_period_seconds = 120

  deployment_controller {
    type = "ECS"
  }
  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }
}