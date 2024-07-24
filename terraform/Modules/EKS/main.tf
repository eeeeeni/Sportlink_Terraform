# resource "aws_eks_cluster" "main" {
#   name     = "main"
#   role_arn = aws_iam_role.eks_role.arn

#   vpc_config {
#     subnet_ids = module.vpc.public_subnets
#   }

#   depends_on = [
#     aws_iam_role_policy.eks_s3_access_policy
#   ]
# }

# resource "aws_eks_node_group" "node_group" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "node-group"
#   node_role_arn       = aws_iam_role.eks_node_role.arn
#   subnet_ids      = module.vpc.private_subnets

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   depends_on = [
#     aws_eks_cluster.main,
#     aws_iam_instance_profile.eks_node_instance_profile
#   ]
# }

# # EKS 클러스터 생성
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"

#   cluster_name    = local.cluster_name
#   cluster_version = local.cluster_version
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

# # 보안 그룹 업데이트 (EKS 클러스터 생성 후)
# resource "aws_security_group_rule" "bastion_to_eks" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   security_group_id        = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
#   source_security_group_id = module.BastionHost_SG.security_group_id

#   depends_on = [module.eks]
# }
