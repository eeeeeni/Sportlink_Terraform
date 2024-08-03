output "REDIS_HOST" {
  description = "Primary endpoint of the Redis cluster"
  value       = module.elasticache_redis.replication_group_primary_endpoint_address
}

# output "redis_reader_endpoint" {
#   description = "Reader endpoint of the Redis cluster"
#   value       = module.elasticache_redis.replication_group_reader_endpoint_address
# }

output "cluster_cache_nodes" {
  description = "List of node objects including `id`, `address`, `port` and `availability_zone`"
  value       = module.elasticache_redis.cluster_cache_nodes
}

# output "redis_arn" {
#   description = "ARN of the Redis cluster"
#   value       = module.elasticache_redis.cluster_arn
# }
