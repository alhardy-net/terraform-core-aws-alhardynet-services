data "aws_partition" "current" {}

data "aws_secretsmanager_secret_version" "postgres" {
  secret_id = "customers/postgres"
}

locals {
  db_identifier           = "customers"
  db_instance_class       = "db.t3.micro"
  db_monitoring_role_name = "RDSMonitoringRole"
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.postgres.secret_string
  )
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${local.db_identifier}-postgres"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_persistence_subnets

  tags = {
    Name               = "${local.db_identifier}-postgres"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_security_group" "postgres" {
  name        = "${local.db_identifier}-postgres-SG"
  description = "Security group for postgres communicate in and out"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name               = "${local.db_identifier}-postgres-SG"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_security_group_rule" "postgres_ports_ingress" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "TCP"
  cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block, data.terraform_remote_state.hub.outputs.vpc_cidr_block]
  security_group_id = aws_security_group.postgres.id
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${local.db_identifier}-postgres-params"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "client_encoding"
    value = "utf8"
  }

  tags = {
    Name               = "${local.db_identifier}-params"
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  name               = local.db_monitoring_role_name
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json

  tags = {
    Name               = local.db_monitoring_role_name
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "postgres" {
  identifier                          = local.db_identifier
  instance_class                      = local.db_instance_class
  allocated_storage                   = var.postgres_allocated_storage
  engine                              = "postgres"
  engine_version                      = "13.3"
  username                            = local.db_creds.username
  password                            = local.db_creds.password
  iam_database_authentication_enabled = true
  port                                = 5432
  multi_az                            = true
  maintenance_window                  = "Sun:00:00-Sun:03:00"
  backup_window                       = "03:00-06:00"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  db_subnet_group_name                = aws_db_subnet_group.postgres.name
  vpc_security_group_ids              = [aws_security_group.postgres.id]
  parameter_group_name                = aws_db_parameter_group.postgres.name
  publicly_accessible                 = false
  skip_final_snapshot                 = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.enhanced_monitoring.arn
}

data "aws_iam_policy_document" "rds_connect" {
  statement {
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.postgres.resource_id}/iam_db_user"]
  }
}

resource "aws_iam_policy" "rds_connect_policy" {
  name        = "CustomersRdsConnectPolicy"
  description = "Allow connect to customers DB"
  policy = data.aws_iam_policy_document.rds_connect.json
}

resource "aws_iam_role_policy_attachment" "api_ecs_task_rds_connect" {
  role       = data.terraform_remote_state.customer_api.outputs.ecs_task_role_name
  policy_arn = aws_iam_policy.rds_connect_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_ecs_task_rds_connect" {
  role       = data.terraform_remote_state.customer_worker.outputs.ecs_task_role_name
  policy_arn = aws_iam_policy.rds_connect_policy.arn
}
