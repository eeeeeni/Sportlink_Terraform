output "eks_cluster_sg_id" {
  description = "Security Group ID for EKS Cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_node_sg_id" {
  description = "Security Group ID for EKS Node Group"
  value       = aws_security_group.eks_node_sg.id
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_node_group_name" {
  description = "EKS Node Group Name"
  value       = aws_eks_node_group.eks_nodes.node_group_name
}
