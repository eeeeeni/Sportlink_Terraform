terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Dev/VPC/terraform.tfstate"
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

module "vpc" {
  source = "../../../Modules/VPC"

  name = "Dev-vpc"
  cidr = "192.168.0.0/24"

  availability_zones = ["ap-northeast-2a"]
  private_subnet_cidr_blocks = ["192.168.2.0/24"]
  public_subnet_cidr_blocks = ["192.168.1.0/24"]


  tags = {
    Environment = "dev"
  }
}
