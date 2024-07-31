output "bastion_host_az1_id" {
  description = "The ID of the Bastion Host in Availability Zone 1"
  value       = aws_instance.BastionHost_AZ1.id
}

output "bastion_host_az2_id" {
  description = "The ID of the Bastion Host in Availability Zone 2"
  value       = aws_instance.BastionHost_AZ2.id
}
