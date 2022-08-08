data "aws_iam_policy_document" "lambda-assume-role-policy" {
  count = var.process_logs ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_decrypt_kms_policy" {
  count = var.process_logs ? 1 : 0
  statement {
    sid    = "AllowDecryptFromKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = var.kms_resources
  }
}

data "aws_iam_policy_document" "cloudwatch_process_logs" {
  count = var.process_logs ? 1 : 0
  statement {
    sid    = "AllowProcessCloudWatchLogs"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${var.source_arn}",
      "${var.source_arn}/*"
    ]
  }

}

resource "aws_iam_role" "cloudwatch_log_processor_lambda" {
  count              = var.process_logs ? 1 : 0
  name               = "${var.env_name}_cloudwatch_log_processor"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy[0].json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log_processor_lambda_execution_role" {
  count      = var.process_logs ? 1 : 0
  role       = aws_iam_role.cloudwatch_log_processor_lambda[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cloudwatch_decrypt_kms" {
  count  = var.process_logs ? 1 : 0
  name   = "${var.env_name}-cloudwatch-decrypt-kms"
  role   = aws_iam_role.cloudwatch_log_processor_lambda[0].id
  policy = data.aws_iam_policy_document.cloudwatch_decrypt_kms_policy[0].json
}

resource "aws_iam_role_policy" "cloudwatch_process_logs" {
  count  = var.process_logs ? 1 : 0
  name   = "${var.env_name}-cloudwatch-process-logs"
  role   = aws_iam_role.cloudwatch_log_processor_lambda[0].id
  policy = data.aws_iam_policy_document.cloudwatch_process_logs[0].json

  depends_on = [aws_iam_role.cloudwatch_log_processor_lambda[0]]
}
