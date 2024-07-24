resource "aws_instance" "bastion" {
  count                       = length(var.public_subnet_ids)
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = element(var.public_subnet_ids, count.index)
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group_id]

  tags = merge(var.tags, { Name = var.name }) 
}
