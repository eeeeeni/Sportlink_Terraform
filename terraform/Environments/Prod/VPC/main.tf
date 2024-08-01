terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Prod/VPC/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "terraform_user"
}

# Prod VPC
module "prod_vpc" {
  source = "github.com/eeeeeni/Terraform-project-VPC"
  name   = "prod_vpc"
  cidr   = local.cidr

  azs              = local.azs
  public_subnets   = local.public_subnet
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    "TerraformManaged" = "true"
    "Environment"      = "prod"
  }
}

# SSH SG
module "SSH_SG" {
  source          = "github.com/eeeeeni/Terraform-project-SG"
  name            = "prod_SSH_SG"
  description     = "SSH Port Allow"
  vpc_id          = module.prod_vpc.vpc_id
  use_name_prefix = false

  ingress_with_cidr_blocks = [
    {
      from_port   = local.ssh_port
      to_port     = local.ssh_port
      protocol    = local.tcp_protocol
      description = "SSH Port Allow"
      cidr_blocks = local.all_network
    },
    {
      from_port   = -1 
      to_port     = -1
      protocol    = local.icmp_protocol
      description = "ICMP Allow"
      cidr_blocks = local.all_network
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.all_network
    }
  ]

  tags = {
    "Name"        = "SSH_SG"
    "Environment" = "prod"
  }
}


