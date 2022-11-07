resource "aws_elasticache_parameter_group" "idp" {
  name   = "${var.env_name}-idp-params"
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

# Multi-AZ redis cluster, used for session storage
resource "aws_elasticache_replication_group" "idp" {
  replication_group_id = "${var.env_name}-idp"
  description          = "Multi AZ redis cluster for the IdP in ${var.env_name}"
  engine               = "redis"
  engine_version       = var.elasticache_redis_engine_version
  node_type            = var.elasticache_redis_node_type
  num_cache_clusters   = var.elasticache_redis_num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.idp.name
  security_group_ids   = [aws_security_group.cache.id]
  subnet_group_name    = aws_elasticache_subnet_group.idp.name
  port                 = 6379
  apply_immediately    = true

  # note that t2.* instances don't support automatic failover
  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = var.elasticache_redis_encrypt_at_rest
  transit_encryption_enabled = var.elasticache_redis_encrypt_in_transit

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache_redis_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
}

###Multi-AZ redis cluster, used for Attempt API Related Storage. Added 09-05-22
resource "aws_elasticache_replication_group" "idp_attempts" {
  replication_group_id = "${var.env_name}-idp-attempts"
  description          = "Multi AZ redis cluster for Attempts API Related Storage in IdP in ${var.env_name}"
  engine               = "redis"
  engine_version       = var.elasticache_redis_engine_version
  node_type            = var.elasticache_redis_attempts_api_node_type
  num_cache_clusters   = 2
  parameter_group_name = aws_elasticache_parameter_group.idp.name
  security_group_ids   = [aws_security_group.cache.id]
  subnet_group_name    = aws_elasticache_subnet_group.idp.name
  apply_immediately    = true

  # note that t2.* instances don't support automatic failover
  multi_az_enabled           = true
  automatic_failover_enabled = true

  #Enable data tiering if using a data tier enabled node.
  data_tiering_enabled = length(regexall("r6gd", var.elasticache_redis_attempts_api_node_type)) != 0 ? true : false

  at_rest_encryption_enabled = var.elasticache_redis_encrypt_at_rest
  transit_encryption_enabled = var.elasticache_redis_encrypt_in_transit

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache_redis_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
}
