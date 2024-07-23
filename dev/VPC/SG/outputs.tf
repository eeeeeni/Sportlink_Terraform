output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "nat_sg_id" {
  value = aws_security_group.nat_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "eks_cluster_sg_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "eks_node_sg_id" {
  value = aws_security_group.eks_node_sg.id
}

