module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.name
  cidr = var.cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  # database_subnets = var.database_subnet_cidr_blocks

  enable_dns_hostnames = true
  enable_dns_support = true

  # enable_nat_gateway = var.enable_nat_gateway
  # single_nat_gateway = var.single_nat_gateway
  # one_nat_gateway_per_az = var.one_nat_gateway_per_az

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
}