aws_region                  = "ap-southeast-2"
aws_account_id              = "171101346296"
aws_assume_role             = "TerraformAccessRole"
customers_api_cpu           = 256
customers_api_memory        = 512
customers_api_desired_count = 1
customers_api_autoscaling = {
  min_capacity              = 1
  max_capacity              = 4
  cooldown_scale_up         = 60
  cooldown_scale_down       = 180
  metric_aggregation_type   = "Average"
  adjustment_type           = "ChangeInCapacity"
  max_cpu_evaluation_period = "3"
  max_cpu_period            = "60"
  max_cpu_threshold         = "85"
  min_cpu_evaluation_period = "3"
  min_cpu_period            = "60"
  min_cpu_threshold         = "10"
}