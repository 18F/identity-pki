module "sms_high_count_check_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  source_code_filename = "sms_high_count.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "sms_high_count.zip"
}

resource "aws_lambda_function" "sms_high_count" {
  filename         = module.sms_high_count_check_code.zip_output_path
  function_name    = "sms_high_count"
  role             = aws_iam_role.sms_count_lambda_role.arn
  description      = "Lambda function that checks for countries with high sms counts"
  handler          = "sms_high_count.lambda_handler"
  source_code_hash = module.sms_high_count_check_code.zip_output_base64sha256
  runtime          = "python3.9"
  timeout          = 300

  environment {
    variables = {
      notification_topic = var.sns_topic_arn_slack_events
      sms_limit          = var.sms_unexpected_country_alarm_threshold
      ignored_countries  = var.ignored_countries
      runbook_url        = var.sms_runbook_url
    }
  }
}


resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "hourly"
  description         = "Fires every hour"
  schedule_expression = "rate(60 minutes)"
}

resource "aws_cloudwatch_event_target" "check_sms_count_every_hour" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "check_sms_high_count"
  arn       = aws_lambda_function.sms_high_count.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sms_high_count" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sms_high_count.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

### IAM Role and Policy for Lambda Function ###

resource "aws_iam_role" "sms_count_lambda_role" {
  name = "SMS_high_count_role-${var.region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "sms_count_lambda_policy" {
  name = "SMS_high_count_policy-${var.region}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "${var.sns_topic_arn_slack_events}"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.sms_count_lambda_cw_logs.arn}:*"
      },
      {
        Action = [

          "logs:*Query*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sms_count_lambda" {
  role       = aws_iam_role.sms_count_lambda_role.name
  policy_arn = aws_iam_policy.sms_count_lambda_policy.arn
}

### Cloudwatch log group for lambda ###
resource "aws_cloudwatch_log_group" "sms_count_lambda_cw_logs" {
  name              = "/aws/lambda/sms_high_count_lambda_logs"
  retention_in_days = 365
}
