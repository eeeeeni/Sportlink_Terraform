output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.prod_vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.prod_vpc.public_subnets
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.prod_vpc.private_subnets
}

output "database_subnet_ids" {
  description = "The IDs of the database subnets"
  value       = module.prod_vpc.database_subnets
}

output "elasticache_subnet_ids" {
  description = "The IDs of the elasticache_subnets"
  value       = module.prod_vpc.elasticache_subnets
}

output "private_subnets" {
  description = "The private subnets CIDR blocks"
  value       = module.prod_vpc.private_subnets_cidr_blocks
}
