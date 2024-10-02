resource "aws_cloudwatch_metric_alarm" "redshift_user_sync_failures" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-redshiftUserSync-failed"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "UserSyncSuccess"
  namespace                 = "Analytics/${var.env_name}"
  period                    = 3600 * 3
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
The Redshift user sync script did NOT complete successfully in the last 3 hours.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}
