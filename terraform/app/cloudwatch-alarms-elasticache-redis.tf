locals {
  # Terraform can't determine member_clusters in an aws_elasticache_replication_group
  # before a plan/apply operation, so this for/format block must be used instead,
  # at least for the time being. TODO: figure out a better way to do this
  # dynamically / with proper resource importing/naming/etc.
  redis_clusters = setunion(
    [for i in range(
      1, 3
    ) : format("%s-%03d", "${var.env_name}-idp-attempts", i)],
    [for i in range(
      1, (var.elasticache_redis_num_cache_clusters + 1)
    ) : format("%s-%03d", "${var.env_name}-idp", i)]
  )
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
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
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
Redis ${each.key} has exceeded ${var.elasticache_redis_alarm_threshold_memory} utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions

  dimensions = {
    CacheClusterId = each.key
  }

  depends_on = [aws_elasticache_replication_group.idp, aws_elasticache_replication_group.idp_attempts]
}

