data "aws_region" "current" {}

resource "aws_iam_role" "pinpoint_event_logger_role" {
  name               = "${var.env}-pinpoint-event-logger-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.pinpoint_event_logger_role_trust.json
}

data "aws_iam_policy_document" "pinpoint_event_logger_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "pinpoint_event_logger_trust_attach" {
  role       = aws_iam_role.pinpoint_event_logger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "pinpoint_event_logger_policy_doc" {
  statement {
    actions = [
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:Describe*",
    ]
    resources = [
      aws_kinesis_stream.pinpoint_kinesis_stream.arn,
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.pinpoint_event_logger.arn}:*",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "pinpoint_event_logger_policy" {
  name        = "${var.env}-pinpoint-event-logger-policy-${data.aws_region.current.name}"
  description = "PinPoint Event Logger"
  policy      = data.aws_iam_policy_document.pinpoint_event_logger_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "pinpoint_event_logger_policy_attach" {
  role       = aws_iam_role.pinpoint_event_logger_role.name
  policy_arn = aws_iam_policy.pinpoint_event_logger_policy.arn
}

resource "aws_cloudwatch_log_group" "pinpoint_event_logger" {
  name              = "/aws/lambda/${var.pinpoint_event_logger_lambda_name}"
  retention_in_days = 365
}

module "lambda_zip" {
  source = "github.com/18F/identity-terraform//null_archive?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  source_code_filename = "pinpoint_event_logger.py"
  source_dir           = "${path.module}/src/"
  zip_filename         = "pinpoint_event_logger.py.zip"
}


resource "aws_lambda_function" "pinpoint_event_logger" {
  depends_on = [
    aws_cloudwatch_log_group.pinpoint_event_logger,
    aws_iam_role.pinpoint_event_logger_role,
    module.lambda_zip.resource_check
  ]
  function_name    = var.pinpoint_event_logger_lambda_name
  description      = "Pinpoint Kinesis to CloudWatch Logging Function"
  filename         = module.lambda_zip.zip_output_path
  source_code_hash = module.lambda_zip.zip_output_base64sha256
  runtime          = "python3.9"
  handler          = "pinpoint_event_logger.lambda_handler"
  timeout          = 600
  memory_size      = 4096
  role             = aws_iam_role.pinpoint_event_logger_role.arn
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  depends_on        = [aws_kinesis_stream.pinpoint_kinesis_stream]
  event_source_arn  = aws_kinesis_stream.pinpoint_kinesis_stream.arn
  function_name     = aws_lambda_function.pinpoint_event_logger.arn
  starting_position = "LATEST"
  batch_size        = 10000
}
