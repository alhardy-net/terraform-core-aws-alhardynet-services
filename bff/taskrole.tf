data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "EcsCluster${local.service_name}TaskRole"

  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
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