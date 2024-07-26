terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "stage/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "Admin3"
    dynamodb_table = "sportlink-terraform-bucket-eni-test-lock"
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
  profile = "Admin3"
}
