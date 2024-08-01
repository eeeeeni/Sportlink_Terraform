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


# ECR 리포지토리 생성
resource "aws_ecr_repository" "sportlink" {
  name                 = "sportlink-ecr"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "sportlink_ECR"
  }
}


output "repository_uri" {
  value = aws_ecr_repository.sportlink.repository_url
}
