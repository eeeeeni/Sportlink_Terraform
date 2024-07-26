# # module "image_s3_bucket" {
# #   source = "../../Modules/S3_image"
# #   bucket_name = "stage-sportlink-image-bucket-stage-test"
# #   environment = "stage"
# # }

# # module "vpc" {
# #   source = "../../Modules/VPC"

# #   name = "stage-vpc"
# #   cidr = "192.168.0.0/16"

# #   availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
# #   private_subnet_cidr_blocks = ["192.168.3.0/24", "192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
# #   public_subnet_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24"]


# #   tags = {
# #     Environment = "stage"
# #   }
# # }

# module "rds_security_group" {
#   source  = "../../Modules/SG"
#   name    = "stage-bastion-sg"
#   vpc_id  = module.vpc.vpc_id

#   tags = {
#     Name = "stage-bastion-sg"
#   }
# }

# module "nat_bastion" {
#   source             = "../../Modules/Bastion"
#   name               = "stage-nat-bastion"
#   vpc_id             = module.vpc.vpc_id
#   public_subnet_ids  = module.vpc.public_subnets
#   private_subnet_ids = module.vpc.private_subnets
#   security_group_id  = module.security_group.security_group_id

#   ami           = "ami-0ea4d4b8dc1e46212"
#   instance_type = "t2.micro"
#   key_name      = "bastion-key"

#   tags = {
#     Name = "stage-nat-bastion"
#   }
# }
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"

#   cluster_name    = "main-cluster"
#   cluster_version = "1.24"
#   vpc_id          = module.vpc.vpc_id
#   subnet_ids      = module.vpc.private_subnets

#   enable_irsa = true

#   eks_managed_node_groups = {
#     EKS_Worker_Node = {
#       instance_types = ["t3.small"]
#       min_size       = 2
#       max_size       = 3
#       desired_size   = 2
#     }
#   }

#   cluster_endpoint_public_access = true

#   enable_cluster_creator_admin_permissions = true
# }

# # EKS 클러스터의 보안 그룹 가져오기
# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
#   depends_on = [module.eks]
# }

# # Bastion 호스트 보안 그룹을 EKS 클러스터의 보안 그룹에 추가
# resource "aws_security_group_rule" "bastion_to_eks" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   security_group_id        = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
#   source_security_group_id = module.nat_bastion.bastion_sg_id

#   depends_on = [module.eks]
# }


# module "iam" {
#   source = "./modules/iam"
#   # IAM 관련 변수 설정
# }

# module "eks" {
#   source = "./modules/eks"
#   # EKS 관련 변수 설정
#   depends_on = [
#     module.vpc,
#     module.security_groups,
#     module.nat_gateway,
#     module.bastion_host,
#     module.iam
#   ]
# }

# module "ecr" {
#   source = "./modules/ecr"
#   # ECR 관련 변수 설정
#   depends_on = [module.iam]
# }

# module "rds" {
#   source = "./modules/rds"
#   # RDS 관련 변수 설정
#   depends_on = [
#     module.vpc,
#     module.security_groups,
#     module.nat_gateway,
#     module.iam
#   ]
# }

# module "route53" {
#   source = "./modules/route53"
#   # Route 53 관련 변수 설정
# }

# module "client_vpn" {
#   source = "./modules/client-vpn"
#   # 클라이언트 VPN 관련 변수 설정
#   depends_on = [module.vpc, module.security_groups]
# }

# module "cloudwatch" {
#   source = "./modules/cloudwatch"
#   # CloudWatch 및 CloudTrail 관련 변수 설정
#   depends_on = [module.vpc, module.security_groups, module.iam]
# }
