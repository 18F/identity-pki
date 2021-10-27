resource "aws_lambda_function" "guard_duty_threat_feed_lambda" {
  filename      = var.guard_duty_threat_feed_code
  function_name = "${var.guard_duty_threat_feed_name}-function"
  role          = aws_iam_role.guard_duty_threat_feed_lambda_role.arn
  description   = "GuardDuty Threat Feed Function"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("${var.guard_duty_threat_feed_code}")
  memory_size      = "3008"
  runtime          = "python3.9"
  timeout          = "300"

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      DAYS_REQUESTED = "${var.days_requested}",
      PUBLIC_KEY     = "${aws_ssm_parameter.guard_duty_threat_feed_public_key.arn}",
      PRIVATE_KEY    = "${aws_ssm_parameter.guard_duty_threat_feed_private_key.arn}",
      OUTPUT_BUCKET  = "${aws_s3_bucket.guard_duty_threat_feed_s3_bucket.id}"
    }
  }
}

resource "aws_lambda_permission" "guard_duty_threat_feed_lambda_permission" {
  statement_id  = "${var.guard_duty_threat_feed_name}-lambda-permission"
  function_name = aws_lambda_function.guard_duty_threat_feed_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guard_duty_threat_feed_rule.arn
}