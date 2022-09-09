
# Multi-AZ redis cluster, used for session storage
resource "aws_elasticache_replication_group" "gitlab" {
  replication_group_id       = "${var.env_name}-gitlab"
  description                = "Multi AZ redis cluster for gitlab in ${var.env_name}"
  engine                     = "redis"
  engine_version             = var.elasticache_redis_engine_version
  node_type                  = var.elasticache_redis_node_type
  num_cache_clusters         = 2
  parameter_group_name       = var.elasticache_redis_parameter_group_name
  security_group_ids         = [aws_security_group.cache.id]
  subnet_group_name          = aws_elasticache_subnet_group.gitlab.name
  port                       = 6379
  transit_encryption_enabled = true

  # note that t2.* instances don't support automatic failover
  automatic_failover_enabled = true

  tags = {
    Name = "${var.name}-${var.env_name} gitlab"
  }
}

resource "aws_s3_object" "gitlab_redis_endpoint" {
  bucket  = data.aws_s3_bucket.secrets.id
  key     = "${var.env_name}/gitlab_redis_endpoint"
  content = aws_elasticache_replication_group.gitlab.primary_endpoint_address

  source_hash = md5(aws_elasticache_replication_group.gitlab.primary_endpoint_address)
}

resource "aws_elasticache_subnet_group" "gitlab" {
  name        = "${var.name}-gitlab-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]
}
