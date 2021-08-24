data "aws_caller_identity" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-networking-vpc-${local.env}"
    }
  }
}

data "terraform_remote_state" "hub" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-networking-hub-prod"
    }
  }
}

data "terraform_remote_state" "customer_api" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-services-customers-${local.env}"
    }
  }
}

data "terraform_remote_state" "customer_worker" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-services-customers-worker-${local.env}"
    }
  }
}