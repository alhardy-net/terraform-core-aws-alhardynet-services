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

variable "customers_worker_cpu" {
  type = number
}

variable "customers_worker_memory" {
  type = number
}

variable "customers_worker_desired_count" {
  type = number
}

variable "customers_worker_autoscaling" {
  description = "Service autoscaling configuration"
  type = object({
    min_capacity              = number
    max_capacity              = number
    cooldown_scale_up         = number
    cooldown_scale_down       = number
    metric_aggregation_type   = string
    adjustment_type           = string
    max_cpu_evaluation_period = string // The number of periods over which data is compared to the specified threshold for max cpu metric alarm
    max_cpu_period            = string // The period in seconds over which the specified statistic is applied for max cpu metric alarm
    max_cpu_threshold         = string // Threshold for max CPU usage
    min_cpu_evaluation_period = string // The number of periods over which data is compared to the specified threshold for min cpu metric alarm
    min_cpu_period            = string // The period in seconds over which the specified statistic is applied for min cpu metric alarm
    min_cpu_threshold         = string // Threshold for min CPU usage
  })
}

variable "postgres_allocated_storage" {
  description = "The postgres RDS instances allocated storage in gigabytes"
  type        = number
  default     = 5
}

# Terraform Cloud
variable "TFC_WORKSPACE_SLUG" {
  type        = string
  default     = "local"
  description = "This is the full slug of the configuration used in this run. This consists of the organization name and workspace name, joined with a slash"
}