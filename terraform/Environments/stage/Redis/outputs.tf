output "REDIS_HOST" {
  description = "Primary endpoint of the Redis cluster"
  value       = module.elasticache_redis.replication_group_primary_endpoint_address
}

output "cluster_cache_nodes" {
  description = "List of node objects including `id`, `address`, `port` and `availability_zone`"
  value       = module.elasticache_redis.cluster_cache_nodes
}

