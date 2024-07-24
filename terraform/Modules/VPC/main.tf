module "vpc" {
  source = "github.com/eeeeeni/Terraform-project-VPC"

  name = var.name
  cidr = var.cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  tags = var.tags
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = module.vpc.vpc_id
  tags   = var.tags
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = var.tags
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(module.vpc.public_subnets)
  subnet_id      = element(module.vpc.public_subnets, count.index)
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id
  tags   = var.tags
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = length(module.vpc.private_subnets)
  subnet_id      = element(module.vpc.private_subnets, count.index)
  route_table_id = aws_route_table.private.id
}
