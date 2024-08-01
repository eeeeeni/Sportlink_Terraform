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

# output "rds_endpoint" {
#   description = "RDS instance endpoint"
#   value       = module.rds.this_db_instance_endpoint
# }

output "db_instance_resource_id" {
  description = "The ID of the RDS instance"
  value       = module.rds.db_instance_resource_id
}