output "bastion_instance_ids" {
  description = "The instance IDs of the Bastion Hosts"
  value = {
    bastion_1 = aws_instance.bastion.id
    bastion_2 = aws_instance.bastion_2.id
  }
}

output "bastion_public_ips" {
  description = "The public IP addresses of the Bastion Hosts"
  value = {
    bastion_1 = aws_instance.bastion.public_ip
    bastion_2 = aws_instance.bastion_2.public_ip
  }
}
