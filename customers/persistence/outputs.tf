output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgres.address
  sensitive   = true
}

output "rds_arn" {
  description = "RDS instance arn"
  value       = aws_db_instance.postgres.arn
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}