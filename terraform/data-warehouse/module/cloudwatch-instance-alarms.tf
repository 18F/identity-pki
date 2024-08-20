resource "aws_cloudwatch_metric_alarm" "redshift_user_sync_failures" {
  alarm_name                = "${var.env_name}_redshift_user_sync_unsuccessful"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "UserSyncSuccess"
  namespace                 = "Analytics/${var.env_name}"
  period                    = 3600 * 3
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This Alarm is executed if the Redshift user sync script has NOT completed successfully in the last 3 hours."
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
}
