resource "aws_security_group" "this" {
  name        = "${local.service_name}-SG"
  description = "Security group for service to communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${local.service_name}-SG"
  }
}

resource "aws_security_group_rule" "bff_api_ports_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, data.terraform_remote_state.hub.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "bff_api_ports_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

module "aws-ecs-service" {
  source        = "app.terraform.io/bytebox/aws-ecs-service/module"
  version       = "0.0.6"
  app_mesh_name = data.terraform_remote_state.ecs.outputs.appmesh_name
  aws_region    = var.aws_region
  cluster_name  = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  container_definition = {
    name      = local.container_name
    port      = local.container_port
    host_port = 80
    environment = [
      {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = local.aspnet_core_env
      }
    ]
  }
  security_group_ids               = [aws_security_group.this.id]
  service_discovery_namespace_id   = data.terraform_remote_state.ecs.outputs.namespace_id
  service_discovery_namespace_name = data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_name
  service_name                     = local.service_name
  subnets                          = data.terraform_remote_state.vpc.outputs.private_application_subnets
  task_definition = {
    family             = local.task_definition_family
    execution_role_arn = data.terraform_remote_state.ecs.outputs.default_task_execution_role_arn
    task_role_arn      = aws_iam_role.ecs_task_role.arn
    cpu                = var.cpu
    memory             = var.memory
    desired_count      = var.desired_count
  }
  app_mesh_virtual_gateway_name         = data.terraform_remote_state.virtualgateway.outputs.appmesh_virtual_gateway_name
  app_mesh_virtual_gateway_match_prefix = "/"
  backend_virtual_service               = [data.terraform_remote_state.customers_service.outputs.virtual_service_name]
  vpc_id                                = data.terraform_remote_state.vpc.outputs.vpc_id
  autoscaling = var.autoscaling
}