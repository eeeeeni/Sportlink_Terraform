terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Dev/RDS/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "terraform_user"
}

# VPC 데이터
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Dev/VPC/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

# Secrets Manager 설정
resource "aws_secretsmanager_secret" "rds_master_password" {
  name = "dev-rds-secret-password-newonelast"
}

resource "aws_secretsmanager_secret_version" "rds_master_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = var.rds_master_password
  })
}

# 로컬 변수 설정
locals {
  tcp_protocol    = "tcp"
  any_port        = 0
  any_protocol    = "-1"
  all_network     = "0.0.0.0/0"
  db_port         = 3306
}

# RDS SG
module "RDS_SG" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "5.1.0"
  name            = "dev_RDS_SG"
  description     = "DB Port Allow"
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  use_name_prefix = "false"

  ingress_with_cidr_blocks = [
    {
      from_port   = local.db_port
      to_port     = local.db_port
      protocol    = local.tcp_protocol
      description = "DB Port Allow"
      cidr_blocks = "192.168.1.0/24"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.all_network
    }
  ]
}


# DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [data.terraform_remote_state.vpc.outputs.private_subnet_ids[0], data.terraform_remote_state.vpc.outputs.fake_subnet_id]

  tags = {
    Name = "rds-subnet-group"
  }
}

module "rds" {
  source                              = "terraform-aws-modules/rds/aws"
  version                             = "6.1.1"
  identifier                          = "dev-rds"
  engine                              = "mysql"
  engine_version                      = "5.7"  # 사용 가능한 버전으로 변경
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 5
  multi_az                            = false
  iam_database_authentication_enabled = true
  manage_master_user_password         = false 
  skip_final_snapshot                 = true
  family                              = "mysql5.7"
  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
  major_engine_version = "5.7"
  db_name              = "devrds"
  username             = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).username
  password             = jsondecode(aws_secretsmanager_secret_version.rds_master_password_version.secret_string).password
  port                 = local.db_port

  # DB subnet group & DB Security-Group
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [module.RDS_SG.security_group_id]
}
