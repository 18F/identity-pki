resource "aws_cloudwatch_event_rule" "guardduty_threat_feed_rule" {
  name                = "${var.guardduty_threat_feed_name}-auto-update"
  description         = "Auto-update GuardDuty threat feed every ${var.guardduty_frequency} days"
  schedule_expression = "rate(${var.guardduty_frequency} days)"
}

resource "aws_cloudwatch_event_target" "guardduty_threat_feed_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_threat_feed_rule.name
  target_id = aws_cloudwatch_event_rule.guardduty_threat_feed_rule.name
  arn       = aws_lambda_function.guardduty_threat_feed_lambda.arn
}