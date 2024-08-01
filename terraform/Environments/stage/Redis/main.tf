terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/redis/terraform.tfstate"
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
    key            = "Stage/VPC/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

# Bastion 데이터
data "terraform_remote_state" "bastion" {
  backend = "s3"
  config = {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/bastion/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

# Redis Security Group
resource "aws_security_group" "redis_sg" {
  name        = "stage-redis-sg"
  description = "Security group for Redis"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow Bastion Host to access Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [data.terraform_remote_state.bastion.outputs.bastion_host_sg_id]
  }

  ingress {
    description = "Allow EKS cluster subnet 1 to access Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["192.168.21.0/24"]
  }

  ingress {
    description = "Allow EKS cluster subnet 2 to access Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["192.168.22.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stage-redis-sg"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "stage-redis-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.elasticache_subnet_ids

  tags = {
    Name = "stage-redis-subnet-group"
  }
}

# ElastiCache Redis 클러스터 설정
module "elasticache_redis" {
  source = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.2.0"

  replication_group_id = "stage-redis-group"
  engine = "redis"
  node_type = "cache.t3.micro"
  num_node_groups = 2
  replicas_per_node_group = 1
  automatic_failover_enabled = true
  multi_az_enabled = true
  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately = true

  subnet_ids = data.terraform_remote_state.vpc.outputs.elasticache_subnet_ids

    # 전송 암호화 설정
  transit_encryption_enabled = true # 전송 암호화 활성화
  transit_encryption_mode    = "preferred" # 전송 암호화 모드 설정

    # 보안 그룹 설정 비활성화
  create_security_group = false  # 보안 그룹 자동 생성 비활성화
  security_group_ids = [aws_security_group.redis_sg.id]  # 수동으로 정의한 보안 그룹 사용

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    }
  ]

  tags = {
    Name = "stage-redis"
    Environment = "stage"
  }
}




