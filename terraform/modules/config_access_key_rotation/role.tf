data "aws_iam_policy_document" "config_access_key_rotation_lambda_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_access_key_rotation_lambda_role" {
  name               = "${var.config_access_key_rotation_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.config_access_key_rotation_lambda_policy.json
}

data "aws_iam_policy_document" "lambda_iam_access" {
  statement {
    sid    = "CreateLogGroupAndEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda.arn,
      "${aws_cloudwatch_log_group.lambda.arn}:*"
    ]
  }
  statement {
    sid    = "SESAccess"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "LambdaAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      aws_iam_role.assumeRole_lambda.arn,
    ]
  }
  statement {
    sid    = "IAMListKeysAndUsers"
    effect = "Allow"
    actions = [
      "iam:ListAccessKeys",
      "iam:ListUsers",
      "iam:ListUserTags"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "config_access_key_rotation_lambda_iam_access" {
  role   = aws_iam_role.config_access_key_rotation_lambda_role.name
  policy = data.aws_iam_policy_document.lambda_iam_access.json

  lifecycle {
    create_before_destroy = true
  }
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