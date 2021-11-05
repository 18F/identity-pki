# Setup IAM role for Lambda
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
  name                = "${var.config_access_key_rotation_name}-role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.config_access_key_rotation_ssm_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"]

  inline_policy {
    name = "${var.config_access_key_rotation_name}-resource-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = "config:ListDiscoveredResources"
            Resource = "*"
          }
        ]
    })
  }

  inline_policy {
    name = "${var.config_access_key_rotation_name}-sns-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = "sns:Publish"
            Resource = "${aws_sns_topic.config_access_key_rotation_topic.arn}"
          }
        ]
    })
  }
}

resource "aws_iam_role" "config_access_key_rotation_lambda_role" {
  name                = "${var.config_access_key_rotation_name}-lambda-role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.config_access_key_rotation_lambda_policy.json
  managed_policy_arns = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
      "arn:aws:iam::aws:policy/AWSLambdaInvocation-DynamoDB"
  ]

  inline_policy {
    name = "${var.config_access_key_rotation_name}-lambda-policy"

    policy = jsonencode(
      {
        Version = "2012-10-17"
        Statement = [
          {
            Action = [
              "dynamodb:PutItem",
              "dynamodb:BatchWriteItem"
            ]
            Effect   = "Allow"
            Resource = "*"
          },
          {
            Action = [
              "ses:SendEmail",
              "ses:SendRawEmail"
            ]
            Effect   = "Allow"
            Resource = "*"
          }
        ]
    })
  }
}
