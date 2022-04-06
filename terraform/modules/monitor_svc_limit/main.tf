locals {
  account_id = data.aws_caller_identity.current.account_id
}

# -- Data Sources Trusted Advisor Refresher Lambda--

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ta_refresher_lambda_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ta_refresher_lambda_policy" {
  statement {
    sid    = "AllowWritesToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ta_refresher_lambda.arn}:*"
    ]
  }
  statement {
    sid    = "AccesstoSupport"
    effect = "Allow"
    actions = [
      "support:*"
    ]
    resources = ["*"]
  }
}

data "archive_file" "ta_refresher_function" {
  type        = "zip"
  source_file = "${path.module}/lambda/ta_refresher.py"
  output_path = "${path.module}/lambda/ta_refresher.zip"
}

data "aws_lambda_function" "ta_refresher_lambda" {
  function_name = aws_lambda_function.ta_refresher_lambda.function_name
  qualifier     = ""
}

# -- Data Sources Trusted Advisor Monitor Lambda--

data "archive_file" "ta_monitor_function" {
  type        = "zip"
  source_file = "${path.module}/lambda/ta_monitor.py"
  output_path = "${path.module}/lambda/ta_monitor.zip"
}

data "aws_lambda_function" "ta_monitor_lambda" {
  function_name = aws_lambda_function.ta_monitor_lambda.function_name
  qualifier     = ""
}

data "aws_iam_policy_document" "ta_monitor_lambda_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ta_monitor_lambda_policy" {
  statement {
    sid    = "AllowWritesToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ta_monitor_lambda.arn}:*"
    ]
  }
  statement {
    sid    = "AccesstoSupport"
    effect = "Allow"
    actions = [
      "support:*"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AccesstoSNS"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = var.sns_topic
  }
}

# -- Trusted Advisor Refresher Lambda Resources --

resource "aws_cloudwatch_log_group" "ta_refresher_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ta_refresher_lambda.function_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "ta_refresher_lambda" {
  filename         = data.archive_file.ta_refresher_function.output_path
  function_name    = var.ta_refresher_lambda_name
  description      = "Refreshes the Trusted Advisor check"
  role             = aws_iam_role.ta_refresher_lambda.arn
  handler          = "ta_refresher.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  source_code_hash = data.archive_file.ta_refresher_function.output_base64sha256
  publish          = false
}

resource "aws_iam_role" "ta_refresher_lambda" {
  name_prefix        = "${var.ta_refresher_lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ta_refresher_lambda_assume.json
}

resource "aws_iam_role_policy" "ta_refresher_lambda" {
  name   = "${var.ta_refresher_lambda_name}-policy"
  role   = aws_iam_role.ta_refresher_lambda.id
  policy = data.aws_iam_policy_document.ta_refresher_lambda_policy.json
}

###Cloudwatch-Lambda invocation###
resource "aws_cloudwatch_event_rule" "ta_refresher_lambda_cronjob" {
  name                = "${var.ta_refresher_lambda_name}-rule"
  schedule_expression = var.refresher_trigger_schedule
}

resource "aws_cloudwatch_event_target" "ta_refresher_invoke_lambda" {
  rule  = aws_cloudwatch_event_rule.ta_refresher_lambda_cronjob.name
  arn   = data.aws_lambda_function.ta_refresher_lambda.arn
  input = var.function_input
}

resource "aws_lambda_permission" "ta_refresher_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ta_refresher_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ta_refresher_lambda_cronjob.arn
}

# -- TA Monitor lambda Resources --

resource "aws_cloudwatch_log_group" "ta_monitor_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ta_monitor_lambda.function_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "ta_monitor_lambda" {
  filename         = data.archive_file.ta_monitor_function.output_path
  function_name    = var.ta_monitor_lambda_name
  description      = "Lambda function monitoring Trusted Advisor"
  role             = aws_iam_role.ta_monitor_lambda.arn
  handler          = "ta_monitor.lambda_handler"
  runtime          = "python3.6"
  timeout          = var.lambda_timeout
  source_code_hash = data.archive_file.ta_monitor_function.output_base64sha256
  publish          = false
  environment {
    variables = {
      notification_topic = jsonencode(var.sns_topic)
    }
  }
}

resource "aws_iam_role" "ta_monitor_lambda" {
  name_prefix        = "${var.ta_monitor_lambda_name}-rule"
  assume_role_policy = data.aws_iam_policy_document.ta_monitor_lambda_assume.json
}

resource "aws_iam_role_policy" "ta_monitor_lambda" {
  name   = "${var.ta_monitor_lambda_name}-role"
  role   = aws_iam_role.ta_monitor_lambda.id
  policy = data.aws_iam_policy_document.ta_monitor_lambda_policy.json
}

###Cloudwatch-Lambda invocation###
resource "aws_cloudwatch_event_rule" "ta_monitor_lambda_cronjob" {
  name                = "${var.ta_monitor_lambda_name}-rule"
  schedule_expression = var.monitor_trigger_schedule
}

resource "aws_cloudwatch_event_target" "ta_monitor_invoke_lambda" {
  rule  = aws_cloudwatch_event_rule.ta_monitor_lambda_cronjob.name
  arn   = data.aws_lambda_function.ta_monitor_lambda.arn
  input = var.function_input
}

resource "aws_lambda_permission" "ta_monitor_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ta_monitor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ta_monitor_lambda_cronjob.arn
}
