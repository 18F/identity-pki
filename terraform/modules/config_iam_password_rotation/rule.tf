resource "aws_cloudwatch_event_rule" "trigger_schedule" {
  name                = "check-iam-user-password-age"
  description         = "Trigger AWS Lambda monitoring IAM User Password Age"
  schedule_expression = var.schedule
}
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.trigger_schedule.name
  target_id = "IAMPasswordLambda"
  arn       = aws_lambda_function.password_rotation_lambda.arn
}
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.password_rotation_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_schedule.arn
}