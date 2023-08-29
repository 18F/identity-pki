data "aws_caller_identity" "current" {}

data "archive_file" "slack_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.py.zip"
}

resource "aws_lambda_function" "lambda_to_slack_notify" {
  filename      = data.archive_file.slack_lambda.output_path
  function_name = "notify-${var.prefix}"
  role          = aws_iam_role.lambda_execution_role.arn
  description   = "Notify AWS WAF managed rule version updates via Slack"
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.slack_lambda.output_base64sha256
  memory_size      = var.lambda_memory_size
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      notification_topic = var.sns_to_slack
    }
  }
}

### IAM Role and Policy for Lambda Function ###
resource "aws_iam_role" "lambda_execution_role" {
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

resource "aws_iam_policy" "lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.notify_lambda_log_group.arn}:*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "notify_lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

### Cloudwatch log group for lambda ###
resource "aws_cloudwatch_log_group" "notify_lambda_log_group" {
  name              = "/aws/lambda/waf-mrg-version-updates"
  retention_in_days = 365
}

resource "aws_lambda_permission" "lambda_invoke_permission" {
  function_name = aws_lambda_function.lambda_to_slack_notify.function_name
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  source_arn    = var.aws_managed_sns_topic
}