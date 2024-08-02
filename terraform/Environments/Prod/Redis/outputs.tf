output "redis_security_group_id" {
  description = "The ID of the Redis security group"
  value = aws_security_group.redis_sg.id
}

output "redis_replication_group_id" {
  description = "The ID of the Redis replication group"
  value = module.elasticache_redis.replication_group_id
}

output "REDIS_HOST" {
  description = "Primary endpoint of the Redis cluster"
  value       = module.elasticache_redis.primary_endpoint
}

output "redis_reader_endpoint" {
  description = "Reader endpoint of the Redis cluster (if applicable)"
  value       = module.elasticache_redis.reader_endpoint
}

output "REDIS_PORT" {
  description = "Port on which the Redis cluster is listening"
  value       = module.elasticache_redis.port
}

output "redis_arn" {
  description = "ARN of the Redis cluster"
  value       = module.elasticache_redis.arn
}

output "redis_cache_cluster_id" {
  description = "Cache cluster ID of the Redis cluster"
  value       = module.elasticache_redis.cache_cluster_id
}
