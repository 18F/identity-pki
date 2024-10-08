resource "aws_cloudwatch_metric_alarm" "reporting_worker_alive_alarm" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-healthCheckerJob-notAlive"
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
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
No background jobs have run for 6 minutes in the app - "Reporting Rails."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

# There should be no failures, so alert on any failure
resource "aws_cloudwatch_metric_alarm" "reporting_worker_failure_alarm" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-workerJobs-failed"
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
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
One or more errors were raised in the background job(s) of the app - "Reporting Rails."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "data_freshness_out_of_range_alarm" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-dataFreshnessJob-outOfRange"
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
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
One or more of the production tables are expected to have newer data from the last update.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "log_column_extractor_failure_alarm" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-logsColumnExtractorJob-failed"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "log-column-extractor-failure"
  namespace                 = "${var.env_name}/reporting-production"
  period                    = "86400"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
The message "LogsColumnExtractorJob: Query executed successfully" has NOT been found in the log group "production.log" since the last update.
The production and/or events table may not have been updated.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "duplicate_row_checker_alert" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-duplicateRowCheckerJob-duplicateRowDetected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "duplicate-row-alert-count"
  namespace                 = "${var.env_name}/reporting-production"
  period                    = "86400"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
Duplicate rows were identified in one or more of the data warehouse tables.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "pii_row_checker_alert" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-piiRowCheckerJob-piiDataDetected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "pii-pattern-row-alert"
  namespace                 = "${var.env_name}/reporting-production"
  period                    = "3600"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
A PII pattern was detected in one or more of the data warehouse tables.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "unexpected_redshift_user_alert" {
  alarm_name                = "${var.env_name}-analytics-reportingRails-redshiftUnexpectedUserDetectionJob-unexpectedUserCreated"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "unexpected-redshift-user"
  namespace                 = "${var.env_name}/reporting-worker"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = local.low_priority_alarm_actions
  ok_actions                = local.low_priority_alarm_actions
  alarm_description         = <<EOM
One or more local users were created in Redshift outside of the user sync script - "redshift_sync.rb."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#workers-alerts
EOM
}
