# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     "mapRoles" = jsonencode([
#       {
#         "rolearn"  = "arn:aws:iam::637423456584:role/eks_node_group-eks-node-group-2024072610573467640000000a"
#         "username" = "system:node:{{EC2PrivateDNSName}}"
#         "groups"   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])

#     "mapUsers" = jsonencode([
#       {
#         "userarn"  = "arn:aws:iam::637423456584:user/admin1"
#         "username" = "admin1"
#         "groups"   = ["system:masters"]
#       },
#       {
#         "userarn"  = "arn:aws:iam::637423456584:user/admin2"
#         "username" = "admin2"
#         "groups"   = ["system:masters"]
#       },
#       {
#         "userarn"  = "arn:aws:iam::637423456584:user/admin3"
#         "username" = "admin_user"
#         "groups"   = ["system:masters"]
#       }
#     ])
#   }
# }
