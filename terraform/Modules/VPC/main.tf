module "vpc" {
  source  = "github.com/eeeeeni/Terraform-project-VPC"

  name = var.name
  cidr = var.cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.tags
}