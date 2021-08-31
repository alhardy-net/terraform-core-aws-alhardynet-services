resource "aws_security_group" "customers_worker_service" {
  name        = "${local.customers_worker_service_name}-SG"
  description = "Security group for customer worker to communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name               = "${local.customers_worker_service_name}-SG"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_security_group_rule" "customers_worker_ports_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, data.terraform_remote_state.hub.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.customers_worker_service.id
}

resource "aws_security_group_rule" "customers_worker_ports_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.customers_worker_service.id
}

module "ecs_service_customers_worker" {
  source        = "app.terraform.io/bytebox/aws-ecs-service/module"
  version       = "0.5.2"
  app_mesh_name = data.terraform_remote_state.ecs.outputs.appmesh_name
  aws_region    = var.aws_region
  cluster_name  = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
  container_definition = {
    name      = local.customers_worker_container_name
    port      = local.customers_worker_container_port
    host_port = 80
    environment = [
      {
        name  = "DOTNET_ENVIRONMENT"
        value = local.dotnet_core_env
      }
    ]
  }
  security_group_ids               = [aws_security_group.customers_worker_service.id]
  service_discovery_namespace_id   = data.terraform_remote_state.ecs.outputs.namespace_id
  service_discovery_namespace_name = data.terraform_remote_state.ecs.outputs.service_discovery_private_dns_namespace_name
  service_name                     = local.customers_worker_service_name
  subnets                          = data.terraform_remote_state.vpc.outputs.private_application_subnets
  task_definition = {
    family             = local.customers_worker_task_definition_family
    execution_role_arn = data.terraform_remote_state.ecs.outputs.default_task_execution_role_arn
    task_role_arn      = aws_iam_role.ecs_task_role.arn
    cpu                = var.customers_worker_cpu
    memory             = var.customers_worker_memory
    desired_count      = var.customers_worker_desired_count
  }
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  autoscaling = var.customers_worker_autoscaling
  env = local.env
}