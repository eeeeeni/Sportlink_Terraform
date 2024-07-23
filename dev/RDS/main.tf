terraform {
  backend "s3" {
    bucket         = "terraform-backend-sportlink"
    key            = "rds/state.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-backend-sportlink-locks"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "sg/state.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 데이터 소스로 VPC와 서브넷을 가져옵니다.
data "aws_vpc" "existing" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

data "aws_subnet" "private" {
  id = data.terraform_remote_state.vpc.outputs.private_subnet2_id
}

data "aws_subnet" "fake" {
  id = data.terraform_remote_state.vpc.outputs.fake_subnet_id
}

data "aws_security_group" "rds" {
  id = data.terraform_remote_state.sg.outputs.rds_sg_id
}

# RDS Subnet Group 생성
resource "aws_db_subnet_group" "main" {
  name       = "dev-rds-subnet-group"
  subnet_ids = [ 
    data.terraform_remote_state.vpc.outputs.private_subnet2_id, 
    data.terraform_remote_state.vpc.outputs.fake_subnet_id
    ]

  tags = {
    Name = "dev-rds-subnet-group"
  }
}

# RDS 인스턴스 생성
resource "aws_db_instance" "main" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "devRDS"
  username               = "admin"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [data.terraform_remote_state.sg.outputs.rds_sg_id]
  skip_final_snapshot    = true

  tags = {
    Name = "dev-rds-instance"
  }
}
