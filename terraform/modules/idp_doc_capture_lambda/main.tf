resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "lambda" {
  filename         = var.lambda_package
  function_name    = var.lambda_name
  description      = var.lambda_description
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "ruby2.7"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = filebase64sha256("${var.lambda_package}")

  environment {
    variables = {
      "S3_BUCKET_NAME" = var.s3_bucket_name
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lamba_cloudwatch" {
  name   = "cloudwatch"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "s3"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_s3.json
}

resource "aws_iam_role_policy" "lambda_kms" {
  name   = "kms"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

data "aws_iam_policy_document" "lambda_assume" {
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

data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    sid    = "cloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.lambda.arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    sid    = "s3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_kms" {
  statement {
    sid    = "KMSDocCaptureKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.kms_key_arn,
    ]
  }
}

resource "aws_ssm_parameter" "lambda_arn" {
  name  = var.ssm_parameter_name
  type  = "String"
  value = aws_lambda_function.lambda.arn
}