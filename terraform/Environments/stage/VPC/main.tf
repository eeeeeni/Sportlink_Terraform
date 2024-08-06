terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Stage/VPC/terraform.tfstate"
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

# Stage VPC
module "stage_vpc" {
  source = "github.com/eeeeeni/Terraform-project-VPC"
  name   = "stage_vpc"
  cidr   = local.cidr

  azs                 = local.azs
  public_subnets      = local.public_subnet
  private_subnets     = local.private_subnets
  elasticache_subnets = local.elasticache_subnets
  database_subnets    = local.database_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  elasticache_subnet_group_name = local.elasticache_subnet_group_name
  tags = {
    "TerraformManaged" = "true"
    "Environment"      = "stage"
  }
}

# SSH SG
module "SSH_SG" {
  source          = "github.com/eeeeeni/Terraform-project-SG"
  name            = "stage_ssh_sg"
  description     = "SSH Port Allow"
  vpc_id          = module.stage_vpc.vpc_id
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
    "Name"        = "stage-ssh-sg"
    "Environment" = "stage"
  }
}


