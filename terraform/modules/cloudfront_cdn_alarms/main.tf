resource "aws_cloudwatch_metric_alarm" "cloudfront_alert" {
  alarm_name          = "CloudFront ${var.env_name} ${var.distribution_name} Total Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "TotalErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = var.threshold

  alarm_description = <<EOM
This CloudFront Distribution alarm goes off when the 4XX/5XX error rate is too high, which can indicate
that the IdP is referencing static assets that do not exist in CloudFront.
  
Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-CloudFront-CDN#totalerrorrate-alarm
EOM

  alarm_actions = var.alarm_actions
  dimensions    = var.dimensions
}
