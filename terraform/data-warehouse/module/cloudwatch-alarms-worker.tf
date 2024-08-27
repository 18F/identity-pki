resource "aws_cloudwatch_metric_alarm" "reporting_worker_alive_alarm" {
  count = var.reporting_worker_alarms_enabled ? 1 : 0

  alarm_name                = "${var.env_name}-ReportingWorkers-Alive"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "6"
  datapoints_to_alarm       = "6"
  metric_name               = "perform-success"
  namespace                 = "${var.env_name}/reporting-worker"
  period                    = "60" # 6 minutes because heartbeat job is queued every 5 minutes, and queue is checked every 5 seconds
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
This alarm is executed when no worker jobs have run for 6 minutes

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}

# There should be no failures, so alert on any failure
resource "aws_cloudwatch_metric_alarm" "reporting_worker_failure_alarm" {
  count = var.reporting_worker_alarms_enabled ? 1 : 0

  alarm_name                = "${var.env_name}-ReportingWorkers-Failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-failure"
  namespace                 = "${var.env_name}/reporting-worker"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
This alarm is executed when a worker job fails

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}

resource "aws_cloudwatch_metric_alarm" "data_freshness_out_of_range_alarm" {
  count = var.data_freshness_alarm_enabled ? 1 : 0

  alarm_name                = "${var.env_name}-DataFreshness-OutOfRange-Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "data-freshness-out-of-range"
  namespace                 = "${var.env_name}/reporting-worker"
  period                    = "3600"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
This alarm is executed if the data freshness is out of range.
This indicates that the production table are not being updated as expected.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}

resource "aws_cloudwatch_metric_alarm" "log_column_extractor_failure_alarm" {
  count = var.log_column_extractor_alarm_enabled ? 1 : 0

  alarm_name                = "${var.env_name}-LogColumnExtractor-failure-Alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "log-column-extractor-failure"
  namespace                 = "${var.env_name}/reporting-production"
  period                    = "86400" # Updated to 24 hours (86400 seconds)
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
This alarm is if the log message "LogsColumnExtractorJob: Query executed successfully" is not found in the production worker log group within the specified period.
This indicates that the production and events table are not being updated as expected.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}

resource "aws_cloudwatch_metric_alarm" "duplicate_row_checker_alert" {
  count                     = var.duplicate_row_checker_alert_enabled ? 1 : 0
  alarm_name                = "${var.env_name}-DuplicateRowChecker-Alert"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "duplicate-row-alert-count"
  namespace                 = "${var.env_name}/reporting-production"
  period                    = "3600"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  alarm_description         = <<EOM
  This alarm is executed when duplicate rows have been identified in the table.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}
