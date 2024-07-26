module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2" 

  name        = var.name
  description = "Security group for Bastion hosts"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow SSH from anywhere"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow ICMP from anywhere"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    },
  ]

  tags = var.tags
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.security_group.security_group_id
}


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

