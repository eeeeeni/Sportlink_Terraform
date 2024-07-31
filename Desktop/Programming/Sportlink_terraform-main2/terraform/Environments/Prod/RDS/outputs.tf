
output "rds_master_username" {
  description = "The master username for the RDS instance"
  value       = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).username
  sensitive   = true
}

output "rds_master_password" {
  description = "The master password for the RDS instance"
  value       = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).password
  sensitive   = true
}
