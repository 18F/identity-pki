data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_decrypt_kms_policy" {
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
  name               = "${var.env_name}_cloudwatch_log_processor"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log_processor_lambda_execution_role" {
  role       = aws_iam_role.cloudwatch_log_processor_lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cloudwatch_decrypt_kms" {
  name   = "${var.env_name}-cloudwatch-decrypt-kms"
  role   = aws_iam_role.cloudwatch_log_processor_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_decrypt_kms_policy.json
}

output "cloudwatch_log_processor_lambda_iam_role" {
  value = aws_iam_role.cloudwatch_log_processor_lambda
}

