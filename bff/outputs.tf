output "virtual_service_name" {
  value       = module.aws-ecs-service.virtual_service_name
  description = "The name of bff api virtual service"
}