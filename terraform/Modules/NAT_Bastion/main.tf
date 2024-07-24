# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : length(var.public_subnet_ids)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(var.public_subnet_ids, count.index % length(var.public_subnet_ids))
  tags          = var.tags
}

resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnet_ids)
}

# Bastion Host Security Group
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

# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = element(var.public_subnet_ids, 0)
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = var.tags
}

# Private Route Table NAT Gateway Route
resource "aws_route" "private_nat" {
  count                  = length(var.private_subnet_ids)
  route_table_id         = element(var.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index % length(aws_nat_gateway.this.*.id))
  
  lifecycle {
    create_before_destroy = true
  }
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}