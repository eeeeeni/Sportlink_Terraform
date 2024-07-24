output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "private_route_table_ids" {
  value = aws_route_table.private.*.id
  description = "List of IDs of private route tables"
}
