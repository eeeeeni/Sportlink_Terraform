terraform {
  backend "s3" {
    bucket  = "sportlink-terraform-backend"
    key     = "Stage/RDS/terraform.tfstate"
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

# RDS 보안 그룹 모듈 호출
module "rds_security_group" {
  source  = "../../../modules/rds/security_group"
  version = "5.1.0"

  name        = "stage-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["192.168.15.0/24", "192.168.16.0/24"]
  ingress_rules       = ["mysql"]
  ingress_rule_ports  = ["3306"]

  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

#aws secretsmanager
resource "aws_secretsmanager_secret" "rds_master_password" {
  name        = "rds-master-password"
  description = "RDS 마스터 사용자 암호"

  tags = {
    Name = "rds-master-password"
  }
}

resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = jsonencode({
    username = var.rds_master_username,
    password = var.rds_master_password
  })
}

module "rds" {
  source                              = "../../../modules/rds"
  identifier                          = "stage-rds"
  engine                              = "mysql"
  engine_version                      = "5.7.42"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 5
  multi_az                            = false
  iam_database_authentication_enabled = true
  master_user_password_secret         = aws_secretsmanager_secret.rds_master_password.arn
  skip_final_snapshot                 = true
  family                              = "mysql5.7"
  vpc_id                              = module.vpc.vpc_id
  private_subnet_ids                  = module.vpc.private_subnets

  ingress_cidr_blocks = [
    # 프라이빗 서브넷 CIDR 블록
    "192.168.15.0/24",
    "192.168.16.0/24"
  ]

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

  tags = {
    Environment = "stage"
    Name        = "stage-rds"
  }
}