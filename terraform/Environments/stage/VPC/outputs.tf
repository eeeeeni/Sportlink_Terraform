output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.stage_vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.stage_vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.stage_vpc.public_subnets
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.stage_vpc.private_subnets
}

output "database_subnet_ids" {
  description = "The IDs of the database subnets"
  value       = module.stage_vpc.database_subnets
}

output "elasticache_subnet_ids" {
  description = "The IDs of the elasticache_subnets"
  value       = module.stage_vpc.elasticache_subnets
}

output "private_subnets" {
  description = "The private subnets CIDR blocks"
  value       = module.stage_vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "The public subnets CIDR blocks"
  value       = module.stage_vpc.public_subnets_cidr_blocks
}
