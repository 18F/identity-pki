# SNS topics used for alarms are expected to be present at the account level
data "aws_sns_topic" "alert_critical" {
  name = var.sns_topic_alert_critical
}

data "aws_sns_topic" "alert_warning" {
  name = var.sns_topic_alert_warning
}

# == Spend limit alarms ==

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_critical" {
  alarm_name        = "${var.env}-SMS-SpendLimit-CRITICAL"
  alarm_description = <<EOM
Pinpoint SMS spending has reached 90% of the monthly limit!
Once this is exceeded, all SMS messages will be rejected. [TF]

Runbook: TODO
EOM


  namespace   = "AWS/SNS"
  metric_name = "SMSMonthToDateSpentUSD"

  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = floor(0.9 * var.pinpoint_spend_limit)
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "missing"

  alarm_actions = [data.aws_sns_topic.alert_critical.arn]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_warning" {
  alarm_name        = "${var.env}-SMS-SpendLimit-WARNING"
  alarm_description = <<EOM
Pinpoint SMS spending has reached 80% of the monthly limit!
Once this is exceeded, all SMS messages will be rejected. [TF]

Runbook: TODO
EOM
  namespace         = "AWS/SNS"
  metric_name       = "SMSMonthToDateSpentUSD"

  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = floor(0.8 * var.pinpoint_spend_limit)
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "missing"

  alarm_actions = [data.aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_daily_warning" {
  alarm_name        = "${var.env}-SMS-SpendLimitDaily-WARNING"
  alarm_description = <<EOM
Pinpoint SMS spending over the past day is on track to exceed the monthly limit
if daily spending is projected monthly.
Once this is exceeded, all SMS messages will be rejected. [TF]

Runbook: TODO
EOM


  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = floor(var.pinpoint_spend_limit / 31)
  evaluation_periods  = 1

  metric_query {
    id          = "e1"
    expression  = "RATE(m1) * 3600 * 24"
    label       = "Daily SMS Spend Rate USD"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      namespace   = "AWS/SNS"
      metric_name = "SMSMonthToDateSpentUSD"
      period      = 86400 # 24h
      stat        = "Maximum"
    }
  }

  alarm_actions = [data.aws_sns_topic.alert_warning.arn]
}

# == Pinpoint error alarms ==

resource "aws_cloudwatch_metric_alarm" "pinpoint_temporary_errors" {
  alarm_name        = "${var.env}-SMS-TemporaryErrors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold [TF]"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessageTemporaryFailure"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = aws_pinpoint_app.main.application_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.pinpoint_error_alarm_threshold
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [data.aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_permanent_errors" {
  alarm_name        = "${var.env}-SMS-PermanentErrors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold [TF]"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessagePermanentFailure"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = aws_pinpoint_app.main.application_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.pinpoint_error_alarm_threshold
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [data.aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_throttled_errors" {
  alarm_name        = "${var.env}-SMS-ThrottledErrors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold [TF]"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessageThrottled"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = aws_pinpoint_app.main.application_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.pinpoint_error_alarm_threshold
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [data.aws_sns_topic.alert_warning.arn]
}

