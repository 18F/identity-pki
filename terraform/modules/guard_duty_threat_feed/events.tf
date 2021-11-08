resource "aws_cloudwatch_event_rule" "guard_duty_threat_feed_rule" {
  name                = "${var.guard_duty_threat_feed_name}-auto-update"
  description         = "Auto-update GuardDuty threat feed every ${var.guard_duty_frequency} days"
  schedule_expression = "rate(${var.guard_duty_frequency} days)"
}

resource "aws_cloudwatch_event_target" "guard_duty_threat_feed_target" {
  rule      = aws_cloudwatch_event_rule.guard_duty_threat_feed_rule.name
  target_id = aws_cloudwatch_event_rule.guard_duty_threat_feed_rule.name
  arn       = aws_lambda_function.guard_duty_threat_feed_lambda.arn
}