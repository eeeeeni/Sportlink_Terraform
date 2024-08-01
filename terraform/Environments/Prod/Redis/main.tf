terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/redis/terraform.tfstate"
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
    key            = "Prod/VPC/terraform.tfstate"
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
    key            = "Prod/bastion/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
    dynamodb_table = "sportlink-terraform-bucket-lock"
    encrypt        = true
  }
}

# Redis Security Group
resource "aws_security_group" "redis_sg" {
  name        = "prod-redis-sg"
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
    cidr_blocks = ["172.16.21.0/24"]
  }

  ingress {
    description = "Allow EKS cluster subnet 2 to access Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["172.16.22.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-redis-sg"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "prod-redis-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.elasticache_subnet_ids

  tags = {
    Name = "prod-redis-subnet-group"
  }
}

# ElastiCache Redis 클러스터 설정
module "elasticache_redis" {
  source = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.2.0"

  replication_group_id = "prod-redis-group"
  engine = "redis"
  node_type = "cache.t3.micro"
  num_node_groups = 2
  replicas_per_node_group = 3
  automatic_failover_enabled = true
  multi_az_enabled = true
  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately = true

  # Security group
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id 
  security_group_ids = [aws_security_group.redis_sg.id]
  subnet_ids = data.terraform_remote_state.vpc.outputs.elasticache_subnets

  #   # 보안 그룹 설정 비활성화
  # create_security_group = false  # 보안 그룹 자동 생성 비활성화
  # security_group_ids = [aws_security_group.redis_sg.id]  # 수동으로 정의한 보안 그룹 사용


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
    Name = "prod-redis"
    Environment = "prod"
  }
}

output "redis_security_group_id" {
  description = "The ID of the Redis security group"
  value = aws_security_group.redis_sg.id
}

output "redis_replication_group_id" {
  description = "The ID of the Redis replication group"
  value = module.elasticache_redis.replication_group_id
}


