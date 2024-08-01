output "BastionHost_AZ1_id" {
  description = "The IDs of the BastionHost_AZ1_id"
  value       = aws_instance.BastionHost_AZ1.id
}

output "BastionHost_AZ2_id" {
  description = "The IDs of the BastionHost_AZ2_id"
  value       = aws_instance.BastionHost_AZ2.id
}

# output "BastionHost_SG_id" {
#   description = "The ID of the Bastion Host Security Group"
#   value       = aws_instance.BastionHost_SG.id
# }