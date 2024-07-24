output "rds_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_subnet_group_name" {
  description = "The name of the RDS subnet group"
  value       = aws_db_subnet_group.main.name
}
