output "instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "The public IP address of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}