resource "aws_cloudwatch_metric_alarm" "cloudfront_alert" {
  alarm_name          = "CloudFront ${var.env_name} ${var.distribution_name} Total Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "TotalErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = var.threshold

  alarm_description = "This CloudFront Distribution alarm is executed when the total error rate exceeds allowed limits"
  alarm_actions     = var.alarm_actions
  dimensions        = var.dimensions
}
