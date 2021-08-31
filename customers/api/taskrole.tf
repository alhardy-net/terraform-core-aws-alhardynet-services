data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_secretsmanager_secret" "customers-shared" {
  name = "customers/shared"
}

data "aws_iam_policy_document" "allow_read_customers_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:Encrypt"]
    resources = ["*"] # TODO: restrict to specific key
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [data.aws_secretsmanager_secret.customers-shared.arn]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "EcsCluster${local.customers_api_service_name}TaskRole"

  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy" "ecs_task_role_read_customer_secrets" {
  policy = data.aws_iam_policy_document.allow_read_customers_secrets.json
  role   = aws_iam_role.ecs_task_role.id
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_envoy_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_xray_write_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_apm_write_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}