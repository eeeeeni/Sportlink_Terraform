terraform {
  backend "s3" {
    bucket         = "backend-test-sportlink-1"  # S3 버킷 이름
    key            = "vpc/state.tfstate"  # S3 내의 상태 파일 경로
    region         = "ap-northeast-2"  # AWS 리전
    dynamodb_table = "test-dynamoDB-sportlink-1"  # 상태 파일 잠금을 위한 DynamoDB 테이블
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block           = "11.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "dev-vpc-1"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "11.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"
  tags = {
    Name = "dev-vpc-public"
  }
}

resource "aws_subnet" "fake" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "11.0.4.0/24"
  availability_zone = "ap-northeast-2b"
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "11.0.2.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-vpc-private-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "11.0.3.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "dev-vpc-private-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "dev-vpc-igw-1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "dev-vpc-public-rt-1"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

