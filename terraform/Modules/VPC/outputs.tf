output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}

# output "database_subnets" {
#   description = "The IDs of the database subnets"
#   value       = module.vpc.database_subnets
# }

# output "nat_gateway_ids" {
#   description = "The IDs of the NAT Gateways"
#   value       = module.vpc.nat_gateway_ids
# }

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}
