output "virtual_service_name" {
  value       = module.ecs_service_customers_worker.virtual_service_name
  description = "The name of customers worker virtual service"
}

output "ecs_task_role_name" {
  value       = aws_iam_role.ecs_task_role.name
  description = "The name of the ecs task role"
}