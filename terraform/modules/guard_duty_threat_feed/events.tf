resource "aws_cloudwatch_event_rule" "guard_duty_threat_feed_rule" {
  name                = "${var.guard_duty_threat_feed_name}-event-rule"
  description         = "GuardDuty threat feed auto update scheduler"
  schedule_expression = "rate(${var.guard_duty_frequency} days)"
}

resource "aws_cloudwatch_event_target" "guard_duty_threat_feed_target" {
  rule      = aws_cloudwatch_event_rule.guard_duty_threat_feed_rule.name
  target_id = aws_cloudwatch_event_rule.guard_duty_threat_feed_rule.name
  arn       = aws_lambda_function.guard_duty_threat_feed_lambda.arn
}