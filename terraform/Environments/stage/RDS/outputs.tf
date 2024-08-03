output "DB_USERNAME" {
  description = "The master username for the RDS instance"
  value       = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).username
  sensitive   = true
}

output "DB_PASSWORD" {
  description = "The master password for the RDS instance"
  value       = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).password
  sensitive   = true
}

output "DB_HOST" {
  value = module.rds.db_instance_endpoint
}

output "DB_NAME" {
  value = module.rds.db_instance_name
}

output "db_instance_resource_id" {
  value = module.rds.db_instance_resource_id
}

output "DB_PORT" {
  value = module.rds.db_instance_port
}



