terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/Grafana/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "terraform_user"
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

# VPC ID 데이터 소스 (기존 VPC 상태 파일 참조)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

# Grafana 인스턴스에 대한 보안 그룹 생성
resource "aws_security_group" "grafana_sg" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 허용할 CIDR 범위
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 허용할 CIDR 범위
  }
}

# Grafana를 설치할 EC2 인스턴스 생성
resource "aws_instance" "grafana" {
  ami           = "ami-0ea4d4b8dc1e46212"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  key_name       = "grafana-key"

  tags = {
    Name = "GrafanaServer"
  }

  user_data = <<-EOF
              sudo yum update -y
              sudo yum install grafana -y
              sudo systemctl start grafana-server
              sudo systemctl enable grafana-server
              echo "Grafana has been installed and started successfully."
              EOF
}
