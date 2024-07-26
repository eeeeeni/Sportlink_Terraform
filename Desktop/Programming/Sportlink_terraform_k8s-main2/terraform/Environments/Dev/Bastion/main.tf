terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Dev/Bastion/terraform.tfstate"
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



module "bastion" {
  source             = "../../../Modules/Bastion"
  name               = "dev-bastion"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  security_group_id  = module.security_group.security_group_id

  ami           = "ami-0ea4d4b8dc1e46212"
  instance_type = "t2.micro"
  key_name      = "bastion-key"

  tags = {
    Name = "dev-bastion"
  }
}