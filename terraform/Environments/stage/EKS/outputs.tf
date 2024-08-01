output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "eks_oidc_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  value       = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "eks_cluster_id" {
  description = "The EKS cluster ID extracted from the OIDC URL"
  value       = regex(".*id/(.+)$", data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer)[0]
}