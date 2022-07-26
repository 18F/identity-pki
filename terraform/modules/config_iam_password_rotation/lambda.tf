data "aws_caller_identity" "current" {}

data "aws_sns_topic" "notify_slack" {
  name = var.slack_events_sns_topic
}

data "aws_sns_topic" "config_password_rotation_topic" {
  name = aws_sns_topic.ssm_to_lambda_notification_topic.name
}

module "config_password_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  source_code_filename = "config_password_rotation.py"
  source_dir           = "${path.module}/lambda/"
  zip_filename         = var.config_password_rotation_code
}

resource "aws_lambda_function" "password_rotation_lambda" {
  filename      = module.config_password_rotation_code.zip_output_path
  function_name = "${var.config_password_rotation_name}-lambda"
  role          = aws_iam_role.password_update_lambda_role.arn
  description   = "Rotates IAM User's Password"
  handler       = "config_password_rotation.lambda_handler"

  source_code_hash = module.config_password_rotation_code.zip_output_base64sha256
  memory_size      = "3008"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      notification_topic = "${data.aws_sns_topic.notify_slack.arn}"
    }
  }

  depends_on = [module.config_password_rotation_code.resource_check]
}

### IAM Role and Policy for Lambda Function ###
resource "aws_iam_role" "password_update_lambda_role" {
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

#resource "aws_iam_role_policy" "password_update_lambda_policy" {
resource "aws_iam_policy" "password_update_lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "${data.aws_sns_topic.notify_slack.arn}"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.password_lambda_cw_logs.arn}:*"
      },
      {
        Action = [
          "iam:GetCredentialReport",
          "iam:GenerateCredentialReport",
          "iam:DeleteLoginProfile"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "password_lambda_logs" {
  role       = aws_iam_role.password_update_lambda_role.name
  policy_arn = aws_iam_policy.password_update_lambda_policy.arn
}

### Cloudwatch log group for lambda ###
resource "aws_cloudwatch_log_group" "password_lambda_cw_logs" {
  name              = "/aws/lambda/${var.config_password_rotation_name}-lambda"
  retention_in_days = 365
}

resource "aws_lambda_permission" "config_password_rotation_lambda_permission" {
  statement_id  = "${var.config_password_rotation_name}-lambda-permission"
  function_name = aws_lambda_function.password_rotation_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.config_password_rotation_topic.arn
}

resource "aws_sns_topic_subscription" "config_password_rotation_lambda_target" {
  topic_arn = data.aws_sns_topic.config_password_rotation_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.password_rotation_lambda.arn
}

resource "aws_sns_topic" "ssm_to_lambda_notification_topic" {
  name = "${var.config_password_rotation_name}-topic"
}