output "endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.this_rds_instance_endpoint
}

output "arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.this_rds_instance_arn
}

output "security_group_id" {
  description = "The ID of the RDS security group"
  value       = module.rds_security_group.security_group_id
}
