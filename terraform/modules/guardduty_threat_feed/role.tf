# Setup IAM role for Lambda
locals {
  guardduty_feedname_iam = replace(var.guardduty_threat_feed_name, "/[^a-zA-Z0-9 ]/", "")
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "guardduty_threat_feed_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "guardduty_threat_feed_access" {
  statement {
    sid    = "${local.guardduty_feedname_iam}GuardDutyAccess"
    effect = "Allow"
    actions = [
      "guardduty:ListDetectors",
      "guardduty:CreateThreatIntelSet",
      "guardduty:GetThreatIntelSet",
      "guardduty:ListThreatIntelSets",
      "guardduty:UpdateThreatIntelSet"
    ]
    resources = [
      "arn:aws:guardduty:${var.region}:${data.aws_caller_identity.current.account_id}:detector/*"
    ]
  }
  statement {
    sid    = "${local.guardduty_feedname_iam}IAMAccess"
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
    ]
  }
  statement {
    sid    = "${local.guardduty_feedname_iam}S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.guardduty_threat_feed_s3_bucket.id}"
    ]
  }
  statement {
    sid    = "${local.guardduty_feedname_iam}S3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.guardduty_threat_feed_s3_bucket.id}/*"
    ]
  }
  statement {
    sid    = "${local.guardduty_feedname_iam}SSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "${aws_ssm_parameter.guardduty_threat_feed_public_key.arn}",
      "${aws_ssm_parameter.guardduty_threat_feed_private_key.arn}"
    ]
  }
}

resource "aws_iam_policy" "guardduty_threat_feed_access" {
  name        = "${local.guardduty_feedname_iam}-lambda-policy"
  description = "Policy for ${var.guardduty_threat_feed_name}-lambda access"
  policy      = data.aws_iam_policy_document.guardduty_threat_feed_access.json
}

resource "aws_iam_role_policy_attachment" "guardduty_threat_feed_basic_lambda" {
  role       = aws_iam_role.guardduty_threat_feed_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "guardduty_threat_feed_access_policies" {
  role       = aws_iam_role.guardduty_threat_feed_lambda_role.name
  policy_arn = aws_iam_policy.guardduty_threat_feed_access.arn
}

resource "aws_iam_role" "guardduty_threat_feed_lambda_role" {
  name               = "${var.guardduty_threat_feed_name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.guardduty_threat_feed_policy.json
}
