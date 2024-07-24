resource "aws_security_group" "bastion_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.name}-bastion-sg"
  description = "Allow SSH and ICMP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP (ping) from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = var.tags
}

resource "aws_instance" "bastion" {
  count                      = length(var.public_subnet_ids)
  ami                        = var.ami
  instance_type              = var.instance_type
  key_name                   = var.key_name
  subnet_id                  = element(var.public_subnet_ids, count.index)
  associate_public_ip_address = true
  vpc_security_group_ids     = [aws_security_group.bastion_sg.id]

  tags = merge(var.tags, { Name = "${var.name}-bastion-${count.index}" })
}

output "bastion_sg_id" {
  description = "The ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}
