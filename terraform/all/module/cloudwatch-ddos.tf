resource "aws_cloudwatch_metric_alarm" "ddos_alert" {
  alarm_name                = "DDoS Alert"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "MetricName"
  namespace                 = "AWS/DDoSProtection"
  period                    = "300"
  statistic                 = "Minimum"
  threshold                 = "1"
  alarm_description         = "This Alarm is executed when a DDoS attack is detected"
  insufficient_data_actions = []
  alarm_actions             = [
    aws_sns_topic.slack_usw2["login-events"].arn,
    aws_sns_topic.opsgenie_alert_usw2.arn
  ]
}
