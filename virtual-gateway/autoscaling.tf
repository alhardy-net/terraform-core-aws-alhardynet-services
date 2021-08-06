resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${aws_ecs_service.service.name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.gateway_autoscaling.max_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.gateway_autoscaling.max_cpu_period
  statistic           = "Maximum"
  threshold           = var.gateway_autoscaling.max_cpu_threshold
  dimensions = {
    ClusterName = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${aws_ecs_service.service.name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.gateway_autoscaling.min_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.gateway_autoscaling.min_cpu_period
  statistic           = "Average"
  threshold           = var.gateway_autoscaling.min_cpu_threshold
  dimensions = {
    ClusterName = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  alarm_actions = [aws_appautoscaling_policy.down.arn]
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${data.terraform_remote_state.ecs.outputs.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.gateway_autoscaling.min_capacity
  max_capacity       = var.gateway_autoscaling.max_capacity
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${aws_ecs_service.service.name}-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${data.terraform_remote_state.ecs.outputs.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = var.gateway_autoscaling.adjustment_type
    cooldown                = var.gateway_autoscaling.cooldown_scale_up
    metric_aggregation_type = var.gateway_autoscaling.metric_aggregation_type

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "down" {
  name               = "${aws_ecs_service.service.name}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${data.terraform_remote_state.ecs.outputs.ecs_cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = var.gateway_autoscaling.adjustment_type
    cooldown                = var.gateway_autoscaling.cooldown_scale_down
    metric_aggregation_type = var.gateway_autoscaling.metric_aggregation_type

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.target]
}