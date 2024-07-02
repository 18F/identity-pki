resource "aws_cloudwatch_event_rule" "trigger_schedule" {
  name                = "check-iam-access-key-age"
  description         = "Trigger AWS Lambda monitoring IAM User Access Key Age"
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.trigger_schedule.name
  target_id = "IAMAccessKeyLambda"
  arn       = aws_lambda_function.config_access_key_rotation.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.config_access_key_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_schedule.arn
}
