output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.eks.arn
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "eks_node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.node_group_name
}

output "eks_node_group_arn" {
  description = "The ARN of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.arn
}

output "eks_node_group_instance_types" {
  description = "The instance types used by the EKS node group"
  value       = aws_eks_node_group.eks_nodes.instance_types
}

output "eks_node_group_subnet_ids" {
  description = "The subnet IDs used by the EKS node group"
  value       = aws_eks_node_group.eks_nodes.subnet_ids
}

output "eks_node_group_scaling_config" {
  description = "The scaling configuration of the EKS node group"
  value = {
    desired_size = aws_eks_node_group.eks_nodes.scaling_config[0].desired_size
    max_size     = aws_eks_node_group.eks_nodes.scaling_config[0].max_size
    min_size     = aws_eks_node_group.eks_nodes.scaling_config[0].min_size
  }
}

output "eks_node_group_remote_access" {
  description = "The remote access configuration of the EKS node group"
  value = {
    ec2_ssh_key = aws_eks_node_group.eks_nodes.remote_access[0].ec2_ssh_key
    security_group_ids = aws_eks_node_group.eks_nodes.remote_access[0].source_security_group_ids
  }
}
