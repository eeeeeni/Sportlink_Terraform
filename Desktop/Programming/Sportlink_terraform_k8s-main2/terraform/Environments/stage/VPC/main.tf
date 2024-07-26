terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Stage/vpc/terraform.tfstate"
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

  name = "stage-vpc"
  cidr = "192.168.0.0/16"

  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnet_cidr_blocks = ["192.168.21.0/24", "192.168.22.0/24", "192.168.23.0/24", "192.168.24.0/24"]
  public_subnet_cidr_blocks = ["192.168.11.0/24", "192.168.12.0/24"] 

  // 퍼블릭 서브넷 : 192.168.1x.0/24
  // 프라비잇 서브넷 : 192.168.2x.0/24


  tags = {
    Environment = "stage"
  }
}


