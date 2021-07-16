variable "aws_region" {
  type        = string
  description = "The region of the hub vpc"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS Account Id of the hub account"
}

variable "aws_assume_role" {
  type        = string
  description = "The AWS Role to assume for the AWS account"
}

variable "health_check_grace_period_seconds" {
  description = <<EOT
    Tasks behind a load balancer are being monitored by it. When a task is seen as unhealthy by the load balancer, the ECS
    service will stop it. It can be an issue on Task startup if the ELB health checks marks the task as unhealthy before
    it had time to warm up. The service would shut the task down prematurely.
    This property defaults to 2 minutes. If you frequently experience tasks being stopped just after being started you
    may need to increase this value.
EOT

  default = 120
}

# Terraform Cloud
variable "TFC_WORKSPACE_SLUG" {
  type        = string
  default     = "local"
  description = "This is the full slug of the configuration used in this run. This consists of the organization name and workspace name, joined with a slash"
}