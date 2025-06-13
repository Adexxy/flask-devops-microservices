output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "username" {
  description = "Database username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.postgres.identifier
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.postgres_subnet_group.name
}