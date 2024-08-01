terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Prod/eks/terraform.tfstate"
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


data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sportlink-terraform-backend"
    key    = "Prod/VPC/terraform.tfstate"
    region = "ap-northeast-2"
    profile = "terraform_user"
  }
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  enable_irsa = true


  eks_managed_node_groups = {
    EKS_Worker_Node = {
      name           = "prod-worker-nodes"
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      key_name       = "eks-key"
        tags = {
          Name = "prod-EKS-worker-node"
        }
    }
  }

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
}


resource "aws_ec2_tag" "private_subnet_tag" {
  for_each    = { for idx, subnet in toset(data.terraform_remote_state.vpc.outputs.private_subnet_ids) : idx => subnet }
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_tag" {
  for_each    = { for idx, subnet in toset(data.terraform_remote_state.vpc.outputs.public_subnet_ids) : idx => subnet }
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}