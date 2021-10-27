# Setup IAM role for Lambda
data "aws_iam_policy_document" "guard_duty_threat_feed_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "guard_duty_threat_feed_lambda_role" {
  name                = "${var.guard_duty_threat_feed_name}-lambda-role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.guard_duty_threat_feed_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "${var.guard_duty_threat_feed_name}-guard-duty-access-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "guardduty:ListDetectors",
              "guardduty:CreateThreatIntelSet",
              "guardduty:GetThreatIntelSet",
              "guardduty:ListThreatIntelSets",
              "guardduty:UpdateThreatIntelSet"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:guardduty:${var.aws_region}:${var.account_id}:detector/*"
          },
          {
            Action = [
              "iam:PutRolePolicy",
              "iam:DeleteRolePolicy"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:iam::${var.account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
          }
        ]
    })
  }

  inline_policy {
    name = "${var.guard_duty_threat_feed_name}-s3-access-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:s3:::${aws_s3_bucket.guard_duty_threat_feed_s3_bucket.id}/*"
          }
        ]
    })
  }

  inline_policy {
    name = "${var.guard_duty_threat_feed_name}-ssm-parameters-access-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "ssm:GetParameters"
            ]
            Effect   = "Allow"
            Resource = "${aws_ssm_parameter.guard_duty_threat_feed_public_key.arn}"
          },
          {
            Action = [
              "ssm:GetParameters"
            ]
            Effect   = "Allow"
            Resource = "${aws_ssm_parameter.guard_duty_threat_feed_private_key.arn}"
          }
        ]
    })
  }
}
