resource "aws_cloudwatch_metric_alarm" "wafv2_blocked_alert" {
  count               = var.wafv2_web_acl_scope == "REGIONAL" ? 1 : 0
  provider            = aws.usw2
  alarm_name          = "${var.env}-wafv2-blocks-exceeded"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = var.waf_alert_blocked_period
  statistic           = "Sum"
  threshold           = var.waf_alert_blocked_threshold
  alarm_description   = <<EOM
More than ${var.waf_alert_blocked_threshold} WAF blocks occured in ${var.waf_alert_blocked_period} seconds

by the ALB WAF rules This could be a run of the mill scan, something worse, or signs of a false positive block.

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-WAF#waf-blocks-exceeded
EOM

  alarm_actions = var.waf_alert_actions
  dimensions = {
    Rule   = "ALL"
    Region = var.region
    WebACL = "${var.env}-idp-waf"
  }
}

resource "aws_cloudwatch_metric_alarm" "wafv2_blocked_alert_cloudfront" {
  count               = var.wafv2_web_acl_scope == "CLOUDFRONT" ? 1 : 0
  provider            = aws.use1
  alarm_name          = "${var.env}-cloudfront-wafv2-blocks-exceeded"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = var.waf_alert_blocked_period
  statistic           = "Sum"
  threshold           = var.waf_alert_blocked_threshold
  alarm_description   = <<EOM
More than ${var.waf_alert_blocked_threshold} WAF blocks occured in ${var.waf_alert_blocked_period} seconds

by the Cloudfront WAF rules This could be a run of the mill scan, something worse, or signs of a false 

positive block. Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-WAF#waf-blocks-exceeded
EOM

  alarm_actions = var.waf_alert_actions
  # This one only has Rule and WebACL instead of Rule/WebACL/Region because of Cloudfront
  dimensions = {
    Rule   = "ALL"
    WebACL = "${var.env}-idp-waf"
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_alert" {
  for_each = toset(
    concat(
      var.aws_shield_resources["application_loadbalancer"],
      var.aws_shield_resources["classic_loadbalancer"],
      var.aws_shield_resources["elastic_ip_address"]
    )
  )
  alarm_name          = "DDoS-Alert-${replace(data.aws_arn.resources[each.value].resource, "/", "-")}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = <<EOM
AWS Shield has detected a possible Distributed Denial of Service (DDoS) attack
Resource: ${data.aws_arn.resources[each.value].resource}
Service: ${data.aws_arn.resources[each.value].service}
Account: ${data.aws_arn.resources[each.value].account}
Region: ${data.aws_arn.resources[each.value].region}

Runbook: https://github.com/18F/identity-devops/wiki/Runbook:-Denial-of-Service#aws-shield
EOM
  alarm_actions       = var.ddos_alert_actions
  dimensions = {
    ResourceArn = "${each.value}"
  }
}
