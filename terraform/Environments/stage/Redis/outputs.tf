output "redis_security_group_id" {
  description = "The ID of the Redis security group"
  value = aws_security_group.redis_sg.id
}

output "redis_replication_group_id" {
  description = "The ID of the Redis replication group"
  value = module.elasticache_redis.replication_group_id
}