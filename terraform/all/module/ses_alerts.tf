resource "aws_cloudwatch_metric_alarm" "ses_email_send_limit" {
  alarm_name          = "ses_email_send_limit"
  alarm_description   = <<EOM
In danger of exceeding ${var.ses_email_limit} emails per 6 hours
Account: ${data.aws_caller_identity.current.account_id}
Region: ${var.region}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook%3A-Email-and-SMTP#ses-send-limit
EOM
  metric_name         = "Send"
  threshold           = var.ses_email_limit
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  period              = 21600 # 6 hours
  namespace           = "AWS/SES"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.slack_usw2["alarms"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ses_email_bounce_rate" {
  count               = var.ses_bounce_rate_threshold > 0 ? 1 : 0
  alarm_name          = "ses_email_bounce_rate"
  alarm_description   = <<EOM
Our SES email bounce rate has exceeded ${format("%.1f", var.ses_bounce_rate_threshold * 100)}% in the last 1 hour.
Account: ${data.aws_caller_identity.current.account_id}
Region: ${var.region}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook%3A-Email-and-SMTP#ses-reputation-bounce-rate
EOM
  metric_name         = "Reputation.BounceRate"
  threshold           = var.ses_bounce_rate_threshold
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  period              = 3600 # 1 hour
  namespace           = "AWS/SES"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.slack_usw2["alarms"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ses_email_bounce_rate_critical" {
  count               = var.ses_bounce_rate_threshold_critical > 0 ? 1 : 0
  alarm_name          = "ses_email_bounce_rate_critical"
  alarm_description   = <<EOM
Our SES email bounce rate has exceeded ${format("%.1f", var.ses_bounce_rate_threshold_critical * 100)}% in the last 1 hour. SES in danger of being suspended.
Account: ${data.aws_caller_identity.current.account_id}
Region: ${var.region}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook%3A-Email-and-SMTP#ses-reputation-bounce-rate
EOM
  metric_name         = "Reputation.BounceRate"
  threshold           = var.ses_bounce_rate_threshold_critical
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  period              = 3600 # 1 hour
  namespace           = "AWS/SES"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.slack_usw2["alarms"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ses_email_complaint_rate" {
  count               = var.ses_complaint_rate_threshold > 0 ? 1 : 0
  alarm_name          = "ses_complaint_rate_threshold"
  alarm_description   = <<EOM
Our SES email complaint rate has exceeded ${format("%.1f", var.ses_complaint_rate_threshold * 100)}% in the last 2 hours.
Account: ${data.aws_caller_identity.current.account_id}
Region: ${var.region}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook%3A-Email-and-SMTP#ses-reputation-complaint-rate
EOM
  metric_name         = "Reputation.ComplaintRate"
  threshold           = var.ses_complaint_rate_threshold
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 2
  evaluation_periods  = 2
  period              = 3600 # 1 hour
  namespace           = "AWS/SES"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.slack_usw2["alarms"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ses_email_complaint_rate_critical" {
  count               = var.ses_complaint_rate_threshold_critical > 0 ? 1 : 0
  alarm_name          = "ses_complaint_rate_threshold_critical"
  alarm_description   = <<EOM
Our SES email complaint rate has exceeded ${format("%.1f", var.ses_complaint_rate_threshold_critical * 100)}% in the last 2 hours. SES in danger of being suspended.
Account: ${data.aws_caller_identity.current.account_id}
Region: ${var.region}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook%3A-Email-and-SMTP#ses-reputation-complaint-rate
EOM
  metric_name         = "Reputation.ComplaintRate"
  threshold           = var.ses_complaint_rate_threshold_critical
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm = 2
  evaluation_periods  = 2
  period              = 3600 # 1 hour
  namespace           = "AWS/SES"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.slack_usw2["alarms"].arn]
}
