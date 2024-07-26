terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Stage/bastion/terraform.tfstate"
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

data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["stage-vpc"]
  }
}

module "bastion" {
  source             = "../../../Modules/Bastion"
  name               = "stage-bastion"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  security_group_id  = module.security_group.security_group_id

  ami           = "ami-0ea4d4b8dc1e46212"
  instance_type = "t3.small"
  key_name      = "bastion-key"

  tags = {
    Name = "stage-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Bastion Host Security Group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "0.0.0.0/0"
    description = "Allow SSH access from specified CIDR blocks"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = "0.0.0.0/0"
    description = "Allow ICMP (ping) from specified CIDR blocks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }
}
