terraform {
  backend "s3" {
    bucket         = "terraform-backend-sportlink"  # S3 버킷 이름
    key            = "sg/state.tfstate"  # S3 내의 상태 파일 경로
    region         = "ap-northeast-2"  # AWS 리전
    dynamodb_table = "terraform-backend-sportlink-locks"  # 상태 파일 잠금을 위한 DynamoDB 테이블
  }
}


provider "aws" {
  region = "ap-northeast-2"
}

# VPC 상태를 불러오기 위한 데이터 소스 설정
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "dev-vpc-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-vpc-bastion-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "dev-vpc-rds-sg"
  description = "Security group for RDS"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-vpc-rds-sg"
  }
}
