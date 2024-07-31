terraform {
  backend "s3" {
    bucket         = "backend-test-sportlink-1"
    key            = "eks/state.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "test-dynamoDB-sportlink-1"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "backend-test-sportlink-1"
    key    = "vpc/state.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "backend-test-sportlink-1"
    key    = "sg/state.tfstate"
    region = "ap-northeast-2"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
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

# Attach policies to the IAM role for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# IAM Role for EKS Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

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

# Attach policies to the IAM role for EKS Nodes
resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read_only_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.20.0"
  cluster_name    = "dev-eks-cluster-test"
  cluster_version = "1.30"
  subnet_ids      = [
    data.terraform_remote_state.vpc.outputs.private_subnet1_id,
    data.terraform_remote_state.vpc.outputs.fake_subnet_id
  ]
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  enable_irsa     = true

  iam_role_arn = aws_iam_role.eks_cluster_role.arn

  eks_managed_node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.small"
      key_name         = "bastion-key"
      subnet_ids       = [data.terraform_remote_state.vpc.outputs.private_subnet1_id]
      iam_role         = aws_iam_role.eks_node_role.arn
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Private Subnet Tag (AWS Load Balancer Controller Tag / internal)
resource "aws_ec2_tag" "private_subnet_tag" {
  for_each = { for idx, subnet in toset([data.terraform_remote_state.vpc.outputs.private_subnet1_id]) : idx => subnet }
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Public Subnet Tag (AWS Load Balancer Controller Tag / internet-facing)
resource "aws_ec2_tag" "public_subnet_tag" {
  for_each = { for idx, subnet in toset([data.terraform_remote_state.vpc.outputs.public_subnet_id, data.terraform_remote_state.vpc.outputs.fake_subnet_id]) : idx => subnet }
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# Add security group rule to allow Bastion Host to access EKS
resource "aws_security_group_rule" "allow_bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = data.terraform_remote_state.sg.outputs.bastion_sg_id
}
