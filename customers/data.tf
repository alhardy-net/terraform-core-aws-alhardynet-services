data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-networking-vpc-${local.env}"
    }
  }
}

data "terraform_remote_state" "ecs" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-platform-ecs-${local.env}"
    }
  }
}

data "terraform_remote_state" "cloud_map" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-platform-cloud-map-${local.env}"
    }
  }
}