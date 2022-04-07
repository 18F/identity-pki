#Monitor and notify AWS Service usage using Trusted Advisor Checks

module "limit_check_lambda" {
  source                     = "../modules/monitor_svc_limit"
  refresher_trigger_schedule = var.refresher_trigger_schedule
  monitor_trigger_schedule   = var.monitor_trigger_schedule
  aws_region                 = var.region
  sns_topic                  = local.low_priority_alarm_actions
}

#Monitor and notify KMS Symmetric calls usage

resource "aws_cloudwatch_metric_alarm" "kms_api" {
  alarm_name                = "kms_api_usage_alert"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "10"
  threshold                 = "80"
  alarm_description         = "KMS Cryptographic operations (symmetric) api request rate has exceeded 80%"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = local.low_priority_alarm_actions

  metric_query {
    id          = "pct_utilization"
    expression  = "(usage_data/SERVICE_QUOTA(usage_data))*100"
    label       = "% Utilization"
    return_data = "true"
  }

  metric_query {
    id          = "usage_data"
    return_data = "false"
    metric {
      metric_name = "CallCount"
      namespace   = "AWS/Usage"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        Class    = "None"
        Resource = "CryptographicOperationsSymmetric"
        Service  = "KMS"
        Type     = "API"
      }
    }
  }
}

# Monitor CloudTrail logs and notify for any LimitExceededError message

resource "aws_cloudwatch_log_metric_filter" "api_throttling" {
  name           = "LimitExceededErrorMessage"
  log_group_name = "CloudTrail/DefaultLogGroup"
  pattern        = "{ ($.errorCode = \"*LimitExceeded\") }"
  metric_transformation {
    name       = "LimitExceededErrorMessage"
    namespace  = "${var.env_name}/CloudTrailMetrics"
    value      = 1
    dimensions = {}
  }
}

resource "aws_cloudwatch_metric_alarm" "api_throttling" {
  alarm_name          = "${var.env_name}-svc_limit_exceeded_error_message"
  alarm_description   = "Monitors the number of LimitExceeded error messages in Cloudtrail logs"
  metric_name         = aws_cloudwatch_log_metric_filter.api_throttling.name
  threshold           = "1"
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = "1"
  evaluation_periods  = "1"
  period              = "300"
  namespace           = "${var.env_name}/CloudTrailMetrics"
  alarm_actions       = local.low_priority_alarm_actions
}
