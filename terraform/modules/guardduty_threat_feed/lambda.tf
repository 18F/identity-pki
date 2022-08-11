module "guardduty_threat_feed_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  source_code_filename = "guardduty_threat_feed.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = var.guardduty_threat_feed_code
}

resource "aws_lambda_function" "guardduty_threat_feed_lambda" {
  filename      = module.guardduty_threat_feed_code.zip_output_path
  function_name = "${var.guardduty_threat_feed_name}-function"
  role          = aws_iam_role.guardduty_threat_feed_lambda_role.arn
  description   = "GuardDuty Threat Feed Function"
  handler       = "guardduty_threat_feed.lambda_handler"

  source_code_hash = module.guardduty_threat_feed_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = "python3.9"
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

  depends_on = [module.guardduty_threat_feed_code.resource_check]
}

resource "aws_lambda_permission" "guardduty_threat_feed_lambda_permission" {
  statement_id  = "${var.guardduty_threat_feed_name}-lambda-permission"
  function_name = aws_lambda_function.guardduty_threat_feed_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_threat_feed_rule.arn
}