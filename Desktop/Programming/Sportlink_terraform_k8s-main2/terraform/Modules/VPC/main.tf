module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.name
  cidr = var.cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  tags = merge(var.tags, {
    "Name" = "${var.name}-vpc"
  })

  public_subnet_tags = {
    Name = "${var.name}-public-subnet"
  }

  private_subnet_tags = {
    Name = "${var.name}-private-subnet"
  }

  public_route_table_tags = {
    Name = "${var.name}-public-routetable"
  }

  private_route_table_tags = {
    Name = "${var.name}-private-routetable"
  }

  nat_gateway_tags = {
    Name = "${var.name}-nat-gateway"
  }

  nat_eip_tags = {
    Name = "${var.name}-nat-eip"
  }
}
