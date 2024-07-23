terraform {
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

# AWS S3 Bucket 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-backend-sportlink"
  tags = {
    Name = "terraform_state"
  }
  force_destroy = true
}

# DynamoDB 테이블 생성
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-backend-sportlink-locks"  # S3 버킷과 유사한 이름
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-backend-sportlink-locks"
  }
}
