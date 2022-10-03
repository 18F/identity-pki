locals {
  redis_clusters = setunion(aws_elasticache_replication_group.idp.member_clusters, aws_elasticache_replication_group.idp_attempts.member_clusters)
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
}

