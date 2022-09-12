# first alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_memory" {
  count               = var.elasticache_redis_num_cache_clusters
  alarm_name          = "${var.env_name} Redis memory high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory
  statistic           = "Average"
  alarm_description   = <<EOM
Redis has exceeded ${var.elasticache_redis_alarm_threshold_memory} utilization for over 60 seconds. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts 
EOM
  alarm_actions       = local.low_priority_alarm_actions
}

# high alert
resource "aws_cloudwatch_metric_alarm" "elasticache_alarm_critical_memory" {
  count               = var.elasticache_redis_num_cache_clusters
  alarm_name          = "${var.env_name} Redis memory critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 60
  threshold           = var.elasticache_redis_alarm_threshold_memory_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis has exceeded ${var.elasticache_redis_alarm_threshold_memory} utilization for over 60 seconds. This is a crticial alert. Please address this to avoid session lock-up or failure.
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Redis-alerts
EOM
  alarm_actions       = local.high_priority_alarm_actions
}

