terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/vpn/terraform.tfstate"
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

# VPC 상태 가져오기
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Stage/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

# ACM 인증서 가져오기
data "aws_acm_certificate" "server" {
  domain = "server"
  most_recent = true
}

data "aws_acm_certificate" "client" {
  domain = "client1.domain.tld"
  most_recent = true
}

# 보안 그룹 생성
resource "aws_security_group" "vpn_secgroup" {
  name   = "vpn-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  description = "Allow inbound traffic from port 443, to the VPN"

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Client VPN 엔드포인트 생성
resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "Client VPN for EKS access"
  server_certificate_arn = data.aws_acm_certificate.server.arn
  client_cidr_block      = "10.100.0.0/22"
  vpc_id                 = data.terraform_remote_state.vpc.outputs.vpc_id  
  security_group_ids     = [aws_security_group.vpn_secgroup.id]
  split_tunnel           = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled = false
  }
}

# 네트워크 연결 설정
resource "aws_ec2_client_vpn_network_association" "vpn_association" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = tolist(data.terraform_remote_state.vpc.outputs.public_subnet_ids)[0]  
}

# 인증 규칙 설정
resource "aws_ec2_client_vpn_authorization_rule" "auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  authorize_all_groups   = true
}


