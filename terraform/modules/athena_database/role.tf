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

output "cloudwatch_log_processor_lambda_iam_role" {
  value = var.process_logs ? aws_iam_role.cloudwatch_log_processor_lambda[0] : null
}

