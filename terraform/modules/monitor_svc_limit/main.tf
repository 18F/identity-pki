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

data "aws_lambda_function" "ta_refresher_lambda" {
  function_name = aws_lambda_function.ta_refresher_lambda.function_name
  qualifier     = ""
}

module "ta_refresher_function_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=9ca808e1cad7add8e7bdccd6aa1199d873d34d54"

  source_code_filename = "ta_refresher.py"
  source_dir           = "${path.module}/ta_refresher/"
  zip_filename         = "ta_refresher.zip"
}

# -- Data Sources Trusted Advisor Monitor Lambda--

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

module "ta_monitor_function_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=9ca808e1cad7add8e7bdccd6aa1199d873d34d54"

  source_code_filename = "ta_monitor.py"
  source_dir           = "${path.module}/ta_monitor/"
  zip_filename         = "ta_monitor.zip"
}

# -- Trusted Advisor Refresher Lambda Resources --

resource "aws_cloudwatch_log_group" "ta_refresher_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ta_refresher_lambda.function_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "ta_refresher_lambda" {
  filename         = module.ta_refresher_function_code.zip_output_path
  function_name    = var.refresher_lambda
  description      = "Refreshes the Trusted Advisor check"
  role             = aws_iam_role.ta_refresher_lambda.arn
  handler          = "ta_refresher.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  source_code_hash = module.ta_refresher_function_code.zip_output_base64sha256
  publish          = false
}

resource "aws_iam_role" "ta_refresher_lambda" {
  name_prefix        = "${var.refresher_lambda}-role"
  assume_role_policy = data.aws_iam_policy_document.ta_refresher_lambda_assume.json
}

resource "aws_iam_role_policy" "ta_refresher_lambda" {
  name   = "${var.refresher_lambda}-policy"
  role   = aws_iam_role.ta_refresher_lambda.id
  policy = data.aws_iam_policy_document.ta_refresher_lambda_policy.json
}

###Cloudwatch-Lambda invocation###
resource "aws_cloudwatch_event_rule" "ta_refresher_lambda_cronjob" {
  name                = "${var.refresher_lambda}-rule"
  schedule_expression = var.refresher_schedule
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
  filename         = module.ta_monitor_function_code.zip_output_path
  function_name    = var.monitor_lambda
  description      = "Lambda function monitoring Trusted Advisor"
  role             = aws_iam_role.ta_monitor_lambda.arn
  handler          = "ta_monitor.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  source_code_hash = module.ta_monitor_function_code.zip_output_base64sha256
  publish          = false
  environment {
    variables = {
      notification_topic = jsonencode(var.sns_topic)
    }
  }
}

resource "aws_iam_role" "ta_monitor_lambda" {
  name_prefix        = "${var.monitor_lambda}-rule"
  assume_role_policy = data.aws_iam_policy_document.ta_monitor_lambda_assume.json
}

resource "aws_iam_role_policy" "ta_monitor_lambda" {
  name   = "${var.monitor_lambda}-role"
  role   = aws_iam_role.ta_monitor_lambda.id
  policy = data.aws_iam_policy_document.ta_monitor_lambda_policy.json
}

###Cloudwatch-Lambda invocation###
resource "aws_cloudwatch_event_rule" "ta_monitor_lambda_cronjob" {
  name                = "${var.monitor_lambda}-rule"
  schedule_expression = var.monitor_schedule
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
