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
  alarm_actions     = ["${var.slack_events_sns_hook_arn}"]
}
