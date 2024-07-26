terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Stage/s3/terraform.tfstate"
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


module "image_s3_bucket" {
  source = "../../../Modules/S3_image"
  bucket_name = "stage-sportlink-image-bucket"
  environment = "stage"
}