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

# AWS S3 Bucket 생성 (상태 파일 저장용)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "backend-test"
  tags = {
    Name = "terraform_state"
  }
  force_destroy = true
}

# DynamoDB 테이블 생성 (상태 파일 잠금용)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "test-dynamoDB"  # S3 버킷과 유사한 이름
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

# AWS S3 Bucket 생성 (이미지 저장용)
resource "aws_s3_bucket" "image_storage" {
  bucket = "test-image-storage"  # 버킷 이름을 유니크하게 설정
  tags = {
    Name = "image_storage"
  }
  force_destroy = true
}
