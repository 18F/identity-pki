locals {
  # Terraform can't determine member_clusters in an aws_elasticache_replication_group
  # before a plan/apply operation, so this for/format block must be used instead,
  # at least for the time being. TODO: figure out a better way to do this
  # dynamically / with proper resource importing/naming/etc.

  idp_redis_clusters = [for i in range(
    1, (var.elasticache_redis_num_cache_clusters + 1)
  ) : format("%s-%03d", "${var.env_name}-idp", i)]

  idp_redis_cache_clusters = var.enable_redis_cache_instance ? [for i in range(
    1, (var.elasticache_redis_cache_num_cache_clusters + 1)
  ) : format("%s-%03d", "${var.env_name}-cache", i)] : []

  idp_redis_ratelimit_clusters = var.enable_redis_ratelimit_instance ? [for i in range(
    1, (var.elasticache_redis_ratelimit_num_cache_clusters + 1)
  ) : format("%s-%03d", "${var.env_name}-ratelimit", i)] : []

  redis_clusters = setunion(local.idp_redis_clusters, local.idp_redis_cache_clusters, local.idp_redis_ratelimit_clusters)
}

# Extract network performance info using an aws_ec2_instance_type data source.
# Each of these MUST point to a node type that has a NetworkPerformance value
# of 'Up to 5 Gigabit' or higher, or the threshold calculations for the
# elasticache_alarm_critical resources cannot be set properly!

data "aws_ec2_instance_type" "idp_network" {
  instance_type = trimprefix(var.elasticache_redis_node_type, "cache.")
}

data "aws_ec2_instance_type" "idp_cache_network" {
  count         = var.enable_redis_cache_instance ? 1 : 0
  instance_type = trimprefix(var.elasticache_redis_cache_node_type, "cache.")
}

data "aws_ec2_instance_type" "idp_ratelimit_network" {
  count         = var.enable_redis_ratelimit_instance ? 1 : 0
  instance_type = trimprefix(var.elasticache_redis_ratelimit_node_type, "cache.")
}


# first alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_memory" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-Memory-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} memory utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.moderate_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# high alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_memory" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-Memory-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} memory utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_cpu" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-CPU-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_cpu
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_cpu} CPU utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.moderate_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_cpu" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-CPU-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_cpu_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_cpu_high} CPU utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_currconnections" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-CurrConnections-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_currconnections
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_currconnections} connections for over 120 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.moderate_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_currconnections" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-CurrConnections-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_currconnections_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_currconnections_high} connections for over 120 seconds. This is a critical alert. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_replication_lag" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-ReplicationLag-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_replication_lag
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_replication_lag} replication lag for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.moderate_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_replication_lag" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key}-Redis-ReplicationLag-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_replication_lag_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_replication_lag_high} replication lag for over 60 seconds. This is a critical alert. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [
    aws_elasticache_replication_group.idp,
    aws_elasticache_replication_group.cache,
    aws_elasticache_replication_group.ratelimit
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_idp_cache_network" {
  for_each            = toset(local.idp_redis_cache_clusters)
  alarm_name          = "${each.key}-Redis-NetworkUsage-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  # NetworkBytesIn and NetworkBytesOut are in GB/minute - Hence the conversion
  # pass network_performance from instance type into calculation
  threshold = tonumber(
    regex(
      "[0-9]+",
      data.aws_ec2_instance_type.idp_cache_network[0].network_performance
  )) * 0.075 * var.elasticache_redis_alarm_threshold_network

  alarm_description = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_network}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions     = local.high_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1073741824" # Conversion of bytes to GB/minute
    label       = "Total Network Throughput"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "NetworkBytesIn"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  metric_query {
    id = "m2"

    metric {
      metric_name = "NetworkBytesOut"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  depends_on = [aws_elasticache_replication_group.cache]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_idp_ratelimit_network" {
  for_each            = toset(local.idp_redis_ratelimit_clusters)
  alarm_name          = "${each.key}-Redis-NetworkUsage-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  # NetworkBytesIn and NetworkBytesOut are in GB/minute - Hence the conversion
  # pass network_performance from instance type into calculation
  threshold = tonumber(
    regex(
      "[0-9]+",
      data.aws_ec2_instance_type.idp_ratelimit_network[0].network_performance
  )) * 0.075 * var.elasticache_redis_alarm_threshold_network

  alarm_description = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_network}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions     = local.high_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1073741824" # Conversion of bytes to GB/minute
    label       = "Total Network Throughput"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "NetworkBytesIn"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  metric_query {
    id = "m2"

    metric {
      metric_name = "NetworkBytesOut"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  depends_on = [aws_elasticache_replication_group.ratelimit]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_idp_network" {
  for_each            = toset(local.idp_redis_clusters)
  alarm_name          = "${each.key}-Redis-NetworkUsage-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  # NetworkBytesIn and NetworkBytesOut are in GB/minute - Hence the conversion
  # pass network_performance from instance type into calculation
  threshold = tonumber(
    regex(
      "[0-9]+",
      data.aws_ec2_instance_type.idp_network.network_performance
  )) * 0.075 * var.elasticache_redis_alarm_threshold_network

  alarm_description = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_network}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Redis-alerts
EOM
  alarm_actions     = local.high_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1073741824" # Conversion of bytes to GB/minute
    label       = "Total Network Throughput"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "NetworkBytesIn"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  metric_query {
    id = "m2"

    metric {
      metric_name = "NetworkBytesOut"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = each.key
      }
    }
  }
  depends_on = [aws_elasticache_replication_group.idp]

  lifecycle {
    create_before_destroy = true
  }
}
