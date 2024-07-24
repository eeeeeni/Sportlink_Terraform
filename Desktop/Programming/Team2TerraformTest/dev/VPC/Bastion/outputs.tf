output "bastion_a_public_ip" {
  description = "The public IP of the first bastion host"
  value       = aws_instance.bastion_a.public_ip
}

output "bastion_b_public_ip" {
  description = "The public IP of the second bastion host"
  value       = aws_instance.bastion_b.public_ip
}
