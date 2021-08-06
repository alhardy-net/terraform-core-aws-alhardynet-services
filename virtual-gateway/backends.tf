terraform {
  backend "remote" {
    organization = "bytebox"

    workspaces {
      prefix = "core-aws-alhardynet-services-virtual-gateway-"
    }
  }
}