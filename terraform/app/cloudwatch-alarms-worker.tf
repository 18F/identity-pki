resource "aws_cloudwatch_metric_alarm" "idp_worker_alive_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-Alive"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "6"
  datapoints_to_alarm       = "6"
  metric_name               = "perform-success"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60" # 6 minutes because heartbeat job is queued every 5 minutes, and queue is checked every 5 seconds
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = <<EOM
This alarm is executed when no worker jobs have run for 6 minutes

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "breaching"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

# There should be no failures, so alert on any failure
resource "aws_cloudwatch_metric_alarm" "idp_worker_failure_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-Failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-failure"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = <<EOM
This alarm is executed when a worker job fails

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_queue_time_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-QueueTime"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "queue-time-milliseconds"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "10000" # Job queue is checked every 5 seconds
  alarm_description         = <<EOM
This alarm is executed when job queue time exceeds allowable limits

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_perform_time_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-IDPWorkers-PerformTime"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "perform-time-milliseconds"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "50000"
  alarm_description         = <<EOM
This alarm is executed when job perform time exceeds allowable limits

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Asynchronous-Workers
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "idp_worker_threatmetrix_js_verification_alarm" {
  count = var.idp_worker_alarms_enabled

  alarm_name                = "${var.env_name}-ThreatMetrix-JSVerification"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  metric_name               = "threatmetrix-js-invalid"
  namespace                 = "${var.env_name}/idp-worker"
  period                    = "3600"
  statistic                 = "Maximum"
  threshold                 = "0"
  alarm_description         = <<EOM
This alarm is executed when Javascript served by LexisNexis ThreatMetrix is not appropriately signed.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-ThreatMetrix-Javascript-verification
EOM
  treat_missing_data        = "missing"
  insufficient_data_actions = []
  alarm_actions             = local.high_priority_alarm_actions
}

