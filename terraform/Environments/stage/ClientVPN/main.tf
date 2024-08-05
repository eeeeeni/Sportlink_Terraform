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

resource "aws_acm_certificate" "vpn" {
  private_key          = file(var.private_key_path)
  certificate_body     = file(var.certificate_path)
  certificate_chain    = var.certificate_chain_path != "" ? file(var.certificate_chain_path) : null

  tags = {
    Name = "vpn-cert"
  }
}

# # VPC 상태 가져오기
# data "terraform_remote_state" "vpc" {
#   backend = "s3"
#   config = {
#     bucket = "sportlink-terraform-backend"
#     key    = "Stage/VPC/terraform.tfstate"
#     region = "ap-northeast-2"
#     profile = "terraform_user"
#   }
# }


# # 클라이언트 VPN 엔드포인트
# resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
#   client_cidr_block       = "172.16.0.0/16"
#   server_certificate_arn  = data.aws_acm_certificate.eeeni_store_cert.arn
#   authentication_options {
#     type = "certificate-authentication"
#     root_certificate_chain_arn = data.aws_acm_certificate.eeeni_store_cert.arn
#   }
#   connection_log_options {
#     enabled = false
#   }
#   vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
#   transport_protocol = "udp"
#   dns_servers        = ["8.8.8.8", "8.8.4.4"]
# }

# # 퍼블릭 서브넷과의 네트워크 연결
# resource "aws_ec2_client_vpn_network_association" "vpn_association_public" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
#   subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]  # 첫 번째 퍼블릭 서브넷의 ID
# }

