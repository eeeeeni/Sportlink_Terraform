terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/Grafana/terraform.tfstate"
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
    key    = "Prod/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

# Grafana 인스턴스에 대한 보안 그룹 생성
resource "aws_security_group" "prod-grafana-sg" {
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

  tags = {
    Name = "prod-Grafana-sg"
  }
}

# Grafana를 설치할 EC2 인스턴스 생성
resource "aws_instance" "grafana" {
  ami           = "ami-0ea4d4b8dc1e46212"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.stage-grafana-sg.id]
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  key_name       = "grafana-key"

  tags = {
    Name = "prod-Grafana-Server"
  }

  user_data = <<-EOF
              #!/bin/bash

              # 시스템 패키지 업데이트
              sudo yum update -y
              
              # Grafana 저장소 파일 생성
              sudo tee /etc/yum.repos.d/grafana.repo <<- 'EOF'
              [grafana]
              name=Grafana
              baseurl=https://packages.grafana.com/oss/rpm
              repo_gpgcheck=1
              enabled=1
              gpgkey=https://packages.grafana.com/gpg.key
              gpgcheck=1
              EOF
              
              # Grafana 패키지 설치
              sudo yum install grafana -y
              
              # Grafana 서버 시작
              sudo systemctl start grafana-server
              
              # Grafana 서버 부팅 시 자동 시작 설정
              sudo systemctl enable grafana-server
              
              # 설치 및 시작 완료 메시지 출력
              echo "Grafana has been installed and started successfully."

              EOF
}
