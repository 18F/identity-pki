# For now not much is here. Subscriptions of type "email" are not supported
# in Terraform, because creating one does not create an ARN immediately.

resource "aws_sns_topic" "devops_high_priority_pinpoint" {
  name = "devops_high_priority_pinpoint"
}

# Subscription that connects the SNS topic to paging.
resource "aws_sns_topic_subscription" "opsgenie_devops_high" {
  topic_arn              = "${aws_sns_topic.devops_high_priority_pinpoint.arn}"
  protocol               = "https"
  endpoint               = "${var.opsgenie_devops_high_endpoint}"
  endpoint_auto_confirms = true
}

# == Spend limit alarms ==

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_critical" {
  alarm_name        = "${var.env} SMS spend limit CRITICAL"
  alarm_description = <<EOM
Pinpoint SMS spending has reached 90% of the monthly limit!
Once this is exceeded, all SMS messages will be rejected.

Runbook: TODO
(Alarm managed by Terraform)
EOM

  namespace   = "AWS/SNS"
  metric_name = "SMSMonthToDateSpentUSD"

  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${floor(0.90 * var.pinpoint_spend_limit)}"
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "missing"

  alarm_actions = ["${aws_sns_topic.devops_high_priority_pinpoint.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_warning" {
  alarm_name        = "${var.env} SMS spend limit WARNING"
  alarm_description = <<EOM
Pinpoint SMS spending has reached 80% of the monthly limit!
Once this is exceeded, all SMS messages will be rejected.

Runbook: TODO
(Alarm managed by Terraform)
EOM
  namespace         = "AWS/SNS"
  metric_name       = "SMSMonthToDateSpentUSD"

  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${floor(0.80 * var.pinpoint_spend_limit)}"
  period              = 3600
  evaluation_periods  = 1

  treat_missing_data = "missing"

  alarm_actions = ["${var.sns_topic_arn_slack_events}"]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_spend_limit_daily_warning" {
  alarm_name        = "${var.env} SMS spend limit daily WARNING"
  alarm_description = <<EOM
Pinpoint SMS spending over the past day is on track to exceed the monthly limit
if daily spending is projected monthly.
Once this is exceeded, all SMS messages will be rejected.

Runbook: TODO
(Alarm managed by Terraform)
EOM

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${floor(var.pinpoint_spend_limit / 31.0)}"
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

  alarm_actions = ["${var.sns_topic_arn_slack_events}"]
}

# == Pinpoint error alarms ==

resource "aws_cloudwatch_metric_alarm" "pinpoint_temporary_errors" {
  alarm_name        = "${var.env} SMS temporary errors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold (Managed by Terraform)"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessageTemporaryFailure"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = "${aws_pinpoint_app.main.application_id}"
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${var.pinpoint_error_alarm_threshold}"
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = ["${var.sns_topic_arn_slack_events}"]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_permanent_errors" {
  alarm_name        = "${var.env} SMS permanent errors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold (Managed by Terraform)"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessagePermanentFailure"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = "${aws_pinpoint_app.main.application_id}"
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${var.pinpoint_error_alarm_threshold}"
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = ["${var.sns_topic_arn_slack_events}"]
}

resource "aws_cloudwatch_metric_alarm" "pinpoint_throttled_errors" {
  alarm_name        = "${var.env} SMS throttled errors"
  alarm_description = "Pinpoint SMS errors exceed alarm threshold (Managed by Terraform)"
  namespace         = "AWS/Pinpoint"
  metric_name       = "DirectSendMessageThrottled"

  dimensions = {
    Channel       = "SMS"
    ApplicationId = "${aws_pinpoint_app.main.application_id}"
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "${var.pinpoint_error_alarm_threshold}"
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = ["${var.sns_topic_arn_slack_events}"]
}
