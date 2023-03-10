locals {

  replication_group_clusters = tomap({
    idp      = local.idp_redis_clusters
    attempts = local.idp_attempts_redis_clusters
  })

}

# Clean up once Redis 7 is deployed
resource "aws_elasticache_parameter_group" "idp" {
  name   = "${var.env_name}-idp-params"
  family = "redis6.x"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

# Cache that will remove values if the cache is full
resource "aws_elasticache_parameter_group" "idp_redis_7_cache" {
  count  = var.enable_redis_cache_instance ? 1 : 0
  name   = "${var.env_name}-idp-params-redis7-cache"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

# Cache that will not delete existing data if the cache is full
resource "aws_elasticache_parameter_group" "idp_redis_7" {
  name   = "${var.env_name}-idp-params-redis7"
  family = "redis7"

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
  parameter_group_name = aws_elasticache_parameter_group.idp_redis_7.name
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
  parameter_group_name = aws_elasticache_parameter_group.idp_redis_7.name
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

module "elasticache_external_access" {
  for_each = local.nessus_public_access_mode ? local.replication_group_clusters : tomap({})
  source   = "../modules/external_elasticache_access/"

  name     = var.name
  env_name = var.env_name
  vpc_id   = aws_vpc.default.id

  cluster_name = each.key
  clusters     = each.value

  public_subnet_ids = [for subnet in aws_subnet.public-ingress : subnet.id]
  data_subnet_ids   = [for subnet in aws_subnet.data-services : subnet.id]
}

resource "aws_elasticache_replication_group" "cache" {
  count                = var.enable_redis_cache_instance ? 1 : 0
  replication_group_id = "${var.env_name}-cache"
  description          = "Multi AZ redis cluster for the IdP cache in ${var.env_name}"
  engine               = "redis"
  engine_version       = var.elasticache_redis_engine_version
  node_type            = var.elasticache_redis_cache_node_type
  num_cache_clusters   = var.elasticache_redis_cache_num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.idp_redis_7_cache[0].name
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

resource "aws_elasticache_replication_group" "ratelimit" {
  count                = var.enable_redis_ratelimit_instance ? 1 : 0
  replication_group_id = "${var.env_name}-ratelimit"
  description          = "Multi AZ redis cluster for the IdP rate limiting ${var.env_name}"
  engine               = "redis"
  engine_version       = var.elasticache_redis_engine_version
  node_type            = var.elasticache_redis_ratelimit_node_type
  num_cache_clusters   = var.elasticache_redis_ratelimit_num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.idp_redis_7.name
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
