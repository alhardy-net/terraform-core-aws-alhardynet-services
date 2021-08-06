aws_region      = "ap-southeast-2"
aws_account_id  = "171101346296"
aws_assume_role = "TerraformAccessRole"
envoy_image     = "840364872350.dkr.ecr.ap-southeast-2.amazonaws.com/aws-appmesh-envoy:v1.18.3.0-prod"
xray_image      = "amazon/aws-xray-daemon:1"
virtual_gateway = {
  cpu           = 256,
  memory        = 512,
  desired_count = 1,
  max_percent   = 200,
  min_percent   = 100
}
gateway_autoscaling = {
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