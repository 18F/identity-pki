locals {
  # Terraform can't determine member_clusters in an aws_elasticache_replication_group
  # before a plan/apply operation, so this for/format block must be used instead,
  # at least for the time being. TODO: figure out a better way to do this
  # dynamically / with proper resource importing/naming/etc.

  idp_attempts_redis_clusters = [for i in range(
    1, 3
  ) : format("%s-%03d", "${var.env_name}-idp-attempts", i)]

  idp_redis_clusters = [for i in range(
    1, (var.elasticache_redis_num_cache_clusters + 1)
  ) : format("%s-%03d", "${var.env_name}-idp", i)]

  redis_clusters = setunion(local.idp_attempts_redis_clusters, local.idp_redis_clusters)

  # Terraform can't determine the network capablity of each node type.
  # This is a map of nodes types to GB/s.
  elasticache_network_performace = {
    "cache.t4g.micro"     = 0.625
    "cache.t4g.small"     = 0.625
    "cache.t4g.medium"    = 0.625
    "cache.t3.micro"      = 0.625
    "cache.t3.small"      = 0.625
    "cache.t3.medium"     = 0.625
    "cache.m6g.large"     = 1.25
    "cache.m6g.xlarge"    = 1.25
    "cache.m6g.2xlarge"   = 1.25
    "cache.m6g.4xlarge"   = 1.25
    "cache.m6g.8xlarge"   = 1.5
    "cache.m6g.12xlarge"  = 2.5
    "cache.m6g.16xlarge"  = 3.125
    "cache.m5.12xlarge"   = 1.25
    "cache.m5.24xlarge"   = 3.125
    "cache.m4.10xlarge"   = 1.25
    "cache.r6g.large"     = 1.25
    "cache.r6g.xlarge"    = 1.25
    "cache.r6g.2xlarge "  = 1.25
    "cache.r6g.4xlarge "  = 1.25
    "cache.r6g.8xlarge"   = 1.5
    "cache.r6g.12xlarge"  = 2.5
    "cache.r6g.16xlarge"  = 3.125
    "cache.r5.large "     = 1.25
    "cache.r5.xlarge "    = 1.25
    "cache.r5.2xlarge "   = 1.25
    "cache.r5.4xlarge "   = 1.25
    "cache.r5.12xlarge"   = 1.25
    "cache.r5.24xlarge"   = 3.125
    "cache.r4.large "     = 1.25
    "cache.r4.xlarge "    = 1.25
    "cache.r4.2xlarge "   = 1.25
    "cache.r4.4xlarge "   = 1.25
    "cache.r4.8xlarge"    = 1.25
    "cache.r4.16xlarge"   = 3.125
    "cache.r6gd.xlarge"   = 1.25
    "cache.r6gd.2xlarge"  = 1.25
    "cache.r6gd.4xlarge"  = 1.25
    "cache.r6gd.8xlarge"  = 1.5
    "cache.r6gd.12xlarge" = 2.5
    "cache.r6gd.16xlarge" = 3.125
  }

  idp_attempts_network = local.elasticache_network_performace[var.elasticache_redis_attempts_api_node_type]

  idp_network = local.elasticache_network_performace[var.elasticache_redis_node_type]

}

# first alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_memory" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis memory high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} memory utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

# high alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_memory" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis memory critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} memory utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_cpu" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis cpu high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_cpu
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_cpu} CPU utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_cpu" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis cpu critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_cpu_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_cpu_high} CPU utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_currconnections" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis currconnections high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_currconnections
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_currconnections} connections for over 120 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_currconnections" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis currconnections critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_currconnections_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_currconnections_high} connections for over 120 seconds. This is a critical alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_replication_lag" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis replication lag high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_replication_lag
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_replication_lag} replication lag for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_replication_lag" {
  for_each            = local.redis_clusters
  alarm_name          = "${each.key} Redis replication lag critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_replication_lag_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_replication_lag_high} replication lag for over 60 seconds. This is a critical alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_idp_attempts_network" {
  for_each            = toset(local.idp_attempts_redis_clusters)
  alarm_name          = "${each.key} Redis Network Usage high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = local.idp_attempts_network * 0.7
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${format("%.1f", 0.7 * 100)}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1000000000"
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
  depends_on = [aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_idp_network" {
  for_each            = toset(local.idp_redis_clusters)
  alarm_name          = "${each.key} Redis Network Usage high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = local.idp_network * 0.7
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${format("%.1f", 100 * 0.7)}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.low_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1000000000"
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
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_idp_attempts_network" {
  for_each            = toset(local.idp_attempts_redis_clusters)
  alarm_name          = "${each.key} Redis Network Usage Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = local.idp_attempts_network * 0.9
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${format("%.1f", 0.9 * 100)}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1000000000"
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
  depends_on = [aws_elasticache_replication_group.idp_attempts]
}

resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_idp_network" {
  for_each            = toset(local.idp_redis_clusters)
  alarm_name          = "${each.key} Redis Network Usage Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = local.idp_network * 0.9
  alarm_description   = <<EOM
Redis ${each.key} has exceeded ${format("%.1f", 0.9 * 100)}% network utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1000000000"
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
}
