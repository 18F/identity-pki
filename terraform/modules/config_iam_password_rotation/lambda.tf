data "aws_caller_identity" "current" {}

module "config_password_rotation_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

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
      temp_role_arn = "${aws_iam_role.assumeRole_lambda.arn}"
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
        Sid    = "AllowSendingEmailViaSES"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Sid    = "AllowAccessToIAMLoginProfile"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "${aws_iam_role.assumeRole_lambda.arn}"
        ]
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.password_lambda_cw_logs.arn}:*"
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

### Additional IAM Role, Lambda can assume with limited permissions to take IAM actions against specific IAM user. Lambda should have permission that is overlap with this policy and the policy that it uses when assuming this role. Goal here is to ensure, lambda while assuming this role can take IAM action against only the specific IAM user. ###
data "aws_iam_policy_document" "trust_policy_allowing_lambda_assumeRole" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = [ aws_iam_role.password_update_lambda_role.arn ]
    }
  }
}

data "aws_iam_policy_document" "identity_policy_allowing_lambda_assumeRole" {
  statement {
    sid    = "AllowAccessToIAMLoginProfile"
    effect = "Allow"
    actions = [
      "iam:DeleteLoginProfile",
      "iam:GetLoginProfile"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "assumeRole_lambda" {
  assume_role_policy = data.aws_iam_policy_document.trust_policy_allowing_lambda_assumeRole.json
}

resource "aws_iam_role_policy" "assumeRole_lambda" {
  role   = aws_iam_role.assumeRole_lambda.id
  policy = data.aws_iam_policy_document.identity_policy_allowing_lambda_assumeRole.json
}