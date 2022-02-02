data "aws_region" "current" {}

# ----------------------------------------------------------------------------------------------------------------------
# AWS LAMBDA Role and Policy
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name               = "${var.env}-lambda-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_trust.json

}

data "aws_iam_policy_document" "lambda_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "custom-policy-doc" {
  statement {
    actions = [
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:Describe*",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:Describe*"
    ]
    resources = [aws_kinesis_stream.pinpoint_kinesis_stream.arn,
    "arn:aws:logs:us-west-2:*:*:*:*"]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "cust-policy" {
  name        = "${var.env}-lambda-cust-policy-${data.aws_region.current.name}"
  description = "Lambda Custom Policy"
  policy      = data.aws_iam_policy_document.custom-policy-doc.json
}

resource "aws_iam_role_policy_attachment" "lambda-role-attach-cust-policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cust-policy.arn
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS LAMBDA EXPECTS A DEPLOYMENT PACKAGE
# A deployment package is a ZIP archive that contains your function code and dependencies.
# ----------------------------------------------------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/python/main.py"
  output_path = "${path.module}/python/main.py.zip"
}

# ----------------------------------------------------------------------------------------------------------------------
# DEPLOY THE LAMBDA FUNCTION
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "pinpoint-lambda" {
  depends_on = [
    aws_cloudwatch_log_group.pinpoint-logs,
    aws_iam_role.lambda_role
  ]
  function_name    = "${var.env}-pinpoint-kinesis-cw-function-${data.aws_region.current.name}"
  description      = "Pinpoint Kinesis CW Lambda Function"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  handler          = "main.lambda_handler"
  timeout          = 30
  memory_size      = 128
  role             = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      env             = "${var.env}"
      log_group_name  = aws_cloudwatch_log_group.pinpoint-logs.name
      log_stream_name = aws_cloudwatch_log_stream.SMSLogs.name
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Lambda function gets events from Kinesis stream
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  depends_on        = [aws_kinesis_stream.pinpoint_kinesis_stream]
  event_source_arn  = aws_kinesis_stream.pinpoint_kinesis_stream.arn
  function_name     = aws_lambda_function.pinpoint-lambda.arn
  starting_position = "LATEST"
}
