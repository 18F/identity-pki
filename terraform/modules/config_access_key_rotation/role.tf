data "aws_iam_policy_document" "config_access_key_rotation_ssm_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "config_access_key_rotation_lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_access_key_rotation_remediation_role" {
  name               = "${var.config_access_key_rotation_name}-ssm-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.config_access_key_rotation_ssm_policy.json
}

resource "aws_iam_role" "config_access_key_rotation_lambda_role" {
  name               = "${var.config_access_key_rotation_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.config_access_key_rotation_lambda_policy.json
}

data "aws_iam_policy_document" "config_access_key_rotation_ssm_access" {
  statement {
    sid       = "${local.accesskeyrotation_name_iam}ResourceAccess"
    effect    = "Allow"
    actions   = ["config:ListDiscoveredResources"]
    resources = ["*"]
  }
  statement {
    sid       = "${local.accesskeyrotation_name_iam}SNSAccess"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${data.aws_sns_topic.config_access_key_rotation_topic.arn}"]
  }
}

resource "aws_iam_policy" "config_access_key_rotation_ssm_access" {
  name        = "${var.config_access_key_rotation_name}-ssm-policy"
  description = "Policy for ${var.config_access_key_rotation_name}-ssm access"
  policy      = data.aws_iam_policy_document.config_access_key_rotation_ssm_access.json
}

resource "aws_iam_role_policy_attachment" "config_access_key_rotation_remediation" {
  role       = aws_iam_role.config_access_key_rotation_remediation_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_role_policy_attachment" "config_access_key_rotation_ssm_access" {
  role       = aws_iam_role.config_access_key_rotation_remediation_role.name
  policy_arn = aws_iam_policy.config_access_key_rotation_ssm_access.arn
}

resource "aws_iam_policy" "config_access_key_rotation_lambda_iam_access" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.config_access_key_rotation_lambda.function_name}:*"
      },
      {
        Action = [
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = "${aws_iam_role.assumeRole_lambda.arn}"
      },
      {
        Action = [
          "iam:ListAccessKeys"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_access_key_rotation_lambda_iam_access" {
  role       = aws_iam_role.config_access_key_rotation_lambda_role.name
  policy_arn = aws_iam_policy.config_access_key_rotation_lambda_iam_access.arn
}

# This is an additional role which Lambda can assume, with limited permissions
# to take IAM actions against a specific IAM user. The function should have
# permissions that overlap with this role's policy and the policy that it uses
# when assuming this role. The goal here is to ensure that while Lambda
# assumes this role, it can only take IAM action against the specific IAM user.
data "aws_iam_policy_document" "trust_policy_allowing_lambda_assumeRole" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.config_access_key_rotation_lambda_role.arn]
    }
  }
}

data "aws_iam_policy_document" "identity_policy_allowing_lambda_assumeRole" {
  statement {
    sid    = "AllowAccessToIAMAccessKey"
    effect = "Allow"
    actions = [
      "iam:UpdateAccessKey",
      "iam:ListAccessKeys"
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