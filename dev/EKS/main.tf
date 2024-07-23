# main.tf
terraform {
  backend "s3" {
    bucket         = "terraform-backend-sportlink"
    key            = "eks/state.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-backend-sportlink-locks"
  }
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

provider "aws" {
  region = "ap-northeast-2"
}

# VPC 및 서브넷 데이터 소스
data "aws_vpc" "existing" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

data "aws_subnet" "public" {
  id = data.terraform_remote_state.vpc.outputs.public_subnet_id
}

data "aws_subnet" "fake" {
  id = data.terraform_remote_state.vpc.outputs.fake_subnet_id
}

data "aws_subnet" "private1" {
  id = data.terraform_remote_state.vpc.outputs.private_subnet1_id
}

data "aws_subnet" "private2" {
  id = data.terraform_remote_state.vpc.outputs.private_subnet2_id
}

# 기존 보안 그룹 데이터 소스
data "aws_security_group" "eks_node_sg" {
  id = data.terraform_remote_state.sg.outputs.eks_node_sg_id
}

data "aws_security_group" "bastion_sg" {
  id = data.terraform_remote_state.sg.outputs.bastion_sg_id
}

# EKS 클러스터를 위한 IAM 역할 생성
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role      = aws_iam_role.eks_cluster.name
}

# EKS 클러스터 생성
resource "aws_eks_cluster" "eks" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.vpc.outputs.public_subnet_id,
      data.terraform_remote_state.vpc.outputs.fake_subnet_id
    ]
  }
}

# EKS 노드 그룹을 위한 IAM 역할 생성
resource "aws_iam_role" "eks_node" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role      = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role      = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role      = aws_iam_role.eks_node.name
}

# EKS 노드 그룹 생성
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "my-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [data.terraform_remote_state.vpc.outputs.private_subnet1_id]  # 실제 노드 그룹은 하나의 서브넷만 사용

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types   = ["t3.medium"]
  remote_access {
    ec2_ssh_key = "bastion-key"
    source_security_group_ids = [
      data.terraform_remote_state.sg.outputs.eks_node_sg_id,
      data.terraform_remote_state.sg.outputs.bastion_sg_id
    ]
  }
}
