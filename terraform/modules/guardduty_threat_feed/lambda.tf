resource "aws_lambda_function" "guardduty_threat_feed_lambda" {
  filename      = var.guardduty_threat_feed_code
  function_name = "${var.guardduty_threat_feed_name}-function"
  role          = aws_iam_role.guardduty_threat_feed_lambda_role.arn
  description   = "GuardDuty Threat Feed Function"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("${var.guardduty_threat_feed_code}")
  memory_size      = "3008"
  runtime          = "python3.8"
  timeout          = "300"

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      DAYS_REQUESTED = "${var.guardduty_days_requested}",
      PUBLIC_KEY     = "${aws_ssm_parameter.guardduty_threat_feed_public_key.name}",
      PRIVATE_KEY    = "${aws_ssm_parameter.guardduty_threat_feed_private_key.name}",
      OUTPUT_BUCKET  = "${aws_s3_bucket.guardduty_threat_feed_s3_bucket.id}"
    }
  }
}

resource "aws_lambda_permission" "guardduty_threat_feed_lambda_permission" {
  statement_id  = "${var.guardduty_threat_feed_name}-lambda-permission"
  function_name = aws_lambda_function.guardduty_threat_feed_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_threat_feed_rule.arn
}