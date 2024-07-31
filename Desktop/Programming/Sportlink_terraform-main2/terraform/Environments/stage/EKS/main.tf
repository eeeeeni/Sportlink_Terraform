terraform {
  backend "s3" {
    bucket         = "sportlink-terraform-backend"
    key            = "Stage/eks/terraform.tfstate"
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
    key    = "Stage/VPC/terraform.tfstate"
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

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "stage-eks"
  cluster_version = "1.30"
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    EKS_Worker_Node = {
      name           = "stage-worker-nodes"
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      key_name       = "eks-key"
      tags = {
        Name = "stage-eks-worker-node"
      }
    }
  }

  cluster_endpoint_public_access            = true
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

resource "kubernetes_namespace" "stage_namespace" {
  metadata {
    name = "stage"  # 생성할 네임스페이스 이름
    labels = {
      env = "stage"
    }
  }
}


# # # --------------------------------------------------------------------------------


# # S3 접근 정책을 JSON 파일에서 가져와 정의
# data "local_file" "s3_access_policy_json" {
#   filename = "${path.module}/iam_policy/s3_access_policy.json"
# }

# resource "aws_iam_policy" "s3_access_policy" {
#   name        = "s3_access_policy_stage"
#   description = "Policy to allow EKS to access the S3 bucket in stage environment"
#   policy      = data.local_file.s3_access_policy_json.content
# }

# # EKS가 S3에 접근하기 위한 IAM 역할 정의
# data "local_file" "s3_access_role_json" {
#   filename = "${path.module}/iam_role/s3_access_role.json"
# }

# resource "aws_iam_role" "eks_s3_access_role" {
#   name               = "eks_s3_access_role_stage"
#   assume_role_policy = data.local_file.s3_access_role_json.content
# }

# # 정의된 역할에 정책을 연결
# resource "aws_iam_role_policy_attachment" "eks_s3_access_role_attachment" {
#   role       = aws_iam_role.eks_s3_access_role.name
#   policy_arn = aws_iam_policy.s3_access_policy.arn
# }


# # # AWS Load Balancer Controller IRSA Configuration

# # 1. AWSLoadBalancerController Policy Create

# data "local_file" "alb_controller_policy_json" {
#   filename = "${path.module}/iam_policy/AWSLoadBalancerControllerPolicy.json"
# }

# resource "aws_iam_policy" "alb_controller_policy" {
#   name        = "AWSLoadBalancerControllerPolicy"
#   description = "Policy to allow access to AWSLoadBalancerController"
#   policy      = data.local_file.alb_controller_policy_json.content
# }

# # 2. AWSLoadBalancerController Role Create & Trust relationship / Policy Attachment 

# data "template_file" "alb_controller_role_json" {
#   template = file("${path.module}/iam_role/AWSLoadBalancerControllerAssumeRole.json")
#   vars = {
#     account_id = data.aws_caller_identity.current.account_id
#     region     = data.aws_region.current.name
#     cluster_id = regex(".*id/(.+)$", data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer)[0]
#   }
# }

# resource "aws_iam_role" "alb_controller_role" {
#   name               = "AWSLoadBalancerControllerRole"
#   assume_role_policy = data.template_file.alb_controller_role_json.rendered
# }

# resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
#   policy_arn = aws_iam_policy.alb_controller_policy.arn
#   role       = aws_iam_role.alb_controller_role.name
# }



# # # Route53(ExternalDNS) IRSA Configuration

# # # 1. ExternalDNS Policy Create

# # data "local_file" "externalDNS_policy_json" {
# #   filename = "${path.module}/iam_policy/ExternalDNSPolicy.json"
# # }

# # resource "aws_iam_policy" "externalDNS_policy" {
# #   name        = "ExternalDNSRoute53AccessPolicy"
# #   description = "Policy to allow access to Route53 Hosting Area"
# #   policy = data.local_file.externalDNS_policy_json.content
# # }


# # # 2. ExternalDNS Role Create & Trust relationship / Policy Attachment 

# # data "template_file" "externalDNS_role_json" {
# #   template = file("${path.module}/iam_role/ExternalDNSAssumeRole.json")
# #   vars = {
# #     account_id = data.aws_caller_identity.current.account_id
# #     region     = data.aws_region.current.name
# #     cluster_id = regex(".*id/(.+)$", data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer)[0]
# #   }
# # }

# # resource "aws_iam_role" "externalDNS_role" {
# #   name = "ExternalDNSRole"
# #   assume_role_policy = data.template_file.externalDNS_role_json.rendered
# # }

# # resource "aws_iam_role_policy_attachment" "externalDNS_policy_attachment" {
# #   policy_arn = aws_iam_policy.externalDNS_policy.arn
# #   role       = aws_iam_role.externalDNS_role.name
# # }


# # # --------------------------------------------------------------------------------

# # # 3. AWSLoadBalancerController Install (Helm Install)

# # # Service Account for AWS Load Balancer Controller
# # resource "kubernetes_service_account" "alb_controller_sa" {
# #   metadata {
# #     name      = "aws-load-balancer-controller"
# #     namespace = "kube-system"
# #     annotations = {
# #       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
# #     }
# #   }
# # }

# # # Helm Release for AWS Load Balancer Controller
# # resource "helm_release" "lb_controller" {
# #   name       = "aws-load-balancer-controller"
# #   repository = "https://aws.github.io/eks-charts"
# #   chart      = "aws-load-balancer-controller"
# #   namespace  = "kube-system"

# #   values = [
# #     <<EOF
# #     serviceAccount:
# #       create: false
# #       name: aws-load-balancer-controller
# #     clusterName: ${module.eks.cluster_name}
# #     region: ${data.aws_region.current.name}
# #     vpcId: ${data.terraform_remote_state.vpc.outputs.vpc_id}
# #     EOF
# #   ]
# # }


# # # 3. ExternalDNS Install ( Helm Install )

# # # Kubernetes Service Account for ExternalDNS
# # resource "kubernetes_service_account" "externalDNS_sa" {
# #   metadata {
# #     name      = "external-dns"
# #     namespace = "kube-system"
# #     annotations = {
# #       "eks.amazonaws.com/role-arn" = aws_iam_role.externalDNS_role.arn
# #     }
# #   }
# # }

# # # Helm Release for ExternalDNS
# # resource "helm_release" "external_dns" {
# #   name       = "external-dns"
# #   repository = "https://charts.bitnami.com/bitnami"
# #   chart      = "external-dns"
# #   namespace  = "kube-system"

# #   # Set을 활용한 Values.yml 정의
# #   set {
# #     name  = "serviceAccount.create"
# #     value = "false"
# #   }
# #   set {
# #     name  = "serviceAccount.name"
# #     value = "external-dns"
# #   }
# #   set {
# #     name  = "provider"
# #     value = "aws"
# #   }
# #   set {
# #     name  = "aws.region"
# #     value = "ap-northeast-2"
# #   }
# #   set {
# #     name  = "domainFilters[0]"
# #     value = "mydevsecops.link"
# #   }
# #   set {
# #     name  = "policy"
# #     value = "sync"
# #   }
# #   set {
# #     name  = "rbac.create"
# #     value = "true"
# #   }
# # }

