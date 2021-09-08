
# Multi-AZ redis cluster, used for session storage
resource "aws_elasticache_replication_group" "gitlab" {
  replication_group_id          = "${var.env_name}-gitlab"
  replication_group_description = "Multi AZ redis cluster for gitlab in ${var.env_name}"
  engine                        = "redis"
  engine_version                = var.elasticache_redis_engine_version
  node_type                     = var.elasticache_redis_node_type
  number_cache_clusters         = 2
  parameter_group_name          = var.elasticache_redis_parameter_group_name
  security_group_ids            = [aws_security_group.cache.id]
  subnet_group_name             = aws_elasticache_subnet_group.gitlab.name
  port                          = 6379
  transit_encryption_enabled    = true
  
  # note that t2.* instances don't support automatic failover
  automatic_failover_enabled = true

  tags = {
    Name = "${var.name}-${var.env_name} gitlab"
  }
}

output "gitlab_redis_endpoint" {
  value = aws_elasticache_replication_group.gitlab.primary_endpoint_address
}
