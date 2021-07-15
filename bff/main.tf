resource "aws_ecs_task_definition" "this" {
  family = "service-bff"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  task_role_arn      = "arn:aws:iam::${var.aws_account_id}:role/EcsClusteralhardynetDefaultTaskRole"
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "particule/helloworld"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_alb_target_group" "group" {
  name        = "${local.service_name}-TG"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip"

  health_check {
    path                = "/ping"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${local.service_name}-TG"
  }
}

resource "aws_alb_listener_rule" "rule" {
  listener_arn = data.terraform_remote_state.ecs.outputs.ecs_cluster_alb_https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.group.arn
  }

  condition {
    host_header {
      values = [local.aws_alb_listener_rule_host_header]
    }
  }
}

resource "aws_security_group" "app_security_group" {
  name        = "${local.service_name}-SG"
  description = "Security group for service to communicate in and out"
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
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.public_subnets // TODO: Should be private subnets
    security_groups  = [aws_security_group.app_security_group.id]
    assign_public_ip = true # TODO: Should be false. Currently required to download image via ecr?
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.group.arn
    container_name   = local.container_name
    container_port   = 80
  }
  deployment_controller {
    type = "ECS"
  }
  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}