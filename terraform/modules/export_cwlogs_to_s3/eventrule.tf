resource "aws_cloudwatch_event_rule" "trigger_lambda" {
  name                = "trigger-lambda-to-export-cwlogs"
  description         = "Triggers lambda once in a day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_daily" {
  rule      = aws_cloudwatch_event_rule.trigger_lambda.name
  target_id = "Triggerlambda"
  arn       = aws_lambda_function.lambdafunction.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdafunction.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_lambda.arn
}