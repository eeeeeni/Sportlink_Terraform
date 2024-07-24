terraform {
  backend "s3" {
    bucket         = "terraform-backend-sportlink"
    key            = "nat/state.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-backend-sportlink-locks"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# VPC 모듈의 출력을 가져오는 데이터 소스
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

# SG 모듈의 출력을 가져오는 데이터 소스
data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "sg/state.tfstate"
    region = "ap-northeast-2"
  }
}

# NAT Gateway를 위한 Elastic IP
resource "aws_eip" "nat" {}

# NAT Gateway 리소스
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_id
  tags = {
    Name = "dev-vpc-nat"
  }
}

# 프라이빗 라우트 테이블
resource "aws_route_table" "private" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  tags = {
    Name = "dev-vpc-private-rt"
  }
}

# NAT Gateway 라우트
resource "aws_route" "nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# 프라이빗 서브넷과 라우트 테이블 연결
resource "aws_route_table_association" "private" {
  subnet_id      = data.terraform_remote_state.vpc.outputs.private_subnet1_id
  route_table_id = aws_route_table.private.id
}
