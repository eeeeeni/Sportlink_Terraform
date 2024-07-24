terraform {
  backend "s3" {
    bucket         = "terraform-backend-sportlink"
    key            = "eks/state.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-backend-sportlink-locks"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "terraform-backend-sportlink"
    key    = "sg/state.tfstate"
    region = "ap-northeast-2"
  }
}

# EKS 모듈 호출
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  # EKS Cluster Setting
  cluster_name    = "dev-cluster"
  cluster_version = "1.26"
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids      = [
    data.terraform_remote_state.vpc.outputs.private_subnet1_id,
    data.terraform_remote_state.vpc.outputs.fake_subnet_id
  ]

  # OIDC(OpenID Connect) 구성 
  enable_irsa = true

  # EKS Worker Node 정의 ( ManagedNode방식 / Launch Template 자동 구성 )
  eks_managed_node_groups = {
    EKS_Worker_Node = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      subnet_ids     = [
        data.terraform_remote_state.vpc.outputs.private_subnet1_id  # 노드 그룹에 올바른 서브넷을 명시합니다.
      ]
    }
  }

  # public-subnet(bastion)과 API와 통신하기 위해 설정(443)
  cluster_endpoint_public_access = true

  # K8s ConfigMap Object "aws_auth" 구성
  enable_cluster_creator_admin_permissions = true
}

# Private Subnet Tag (AWS Load Balancer Controller Tag / internal)
resource "aws_ec2_tag" "private_subnet_tag" {
  count = 1
  resource_id = data.terraform_remote_state.vpc.outputs.private_subnet1_id
  key   = "kubernetes.io/role/internal-elb"
  value = "1"
}

# Public Subnet Tag (AWS Load Balancer Controller Tag / internet-facing)
resource "aws_ec2_tag" "public_subnet_tag" {
  count = 1
  resource_id = data.terraform_remote_state.vpc.outputs.public_subnet_id
  key   = "kubernetes.io/role/elb"
  value = "1"
}