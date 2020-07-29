# == Lambda: audit-github ==
resource "aws_lambda_function" "audit-github" {
  count = var.lambda_audit_github_enabled

  s3_bucket = module.s3_shared_uw2.buckets["lambda-functions"]
  s3_key    = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

  lifecycle {
    ignore_changes = [
      s3_key,
      last_modified,
    ]
  }

  function_name = "audit-github"
  description   = "18F/identity-lambda-functions: GithubAuditor -- auditor of Github teams and membership"
  role          = aws_iam_role.lambda-audit-github[0].arn
  handler       = "main.IdentityAudit::GithubAuditor.process"
  runtime       = "ruby2.5"
  timeout       = 30 # seconds

  environment {
    variables = {
      #DEBUG = "1"
      DEBUG     = var.lambda_audit_github_debug == 1 ? "1" : ""
      LOG_LEVEL = "0"
    }
  }

  tags = {
    source_repo = "https://github.com/18F/identity-lambda-functions"
  }
}

# Alert on errors
module "audit-github-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=0290e16a1789f986721a722337b6a9166bcebbc6"
  
  enabled              = var.lambda_audit_github_enabled
  function_name        = var.lambda_audit_github_enabled == 1 ? aws_lambda_function.audit-github[0].function_name : ""
  alarm_actions        = [var.slack_events_sns_hook_arn]
  error_rate_threshold = 1 # percent
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-audit-github" {
  count = var.lambda_audit_github_enabled
  name  = "lambda-audit-github"

  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

resource "aws_iam_role_policy" "lambda-audit-github-policy" {
  count = var.lambda_audit_github_enabled

  name = "lambda-audit-github-policy"
  role = aws_iam_role.lambda-audit-github[0].id

  # Allow accessing necessary secrets
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/lambda/audit-github-token*",
                "arn:aws:secretsmanager:*:*:secret:global/common/github/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ses:SendRawEmail",
            "Resource": "*"
        }
    ]
}
EOM

}

# allow audit-github to send logs
resource "aws_iam_role_policy_attachment" "lambda-audit-github-logs" {
  count = var.lambda_audit_github_enabled

  role       = aws_iam_role.lambda-audit-github[0].name
  policy_arn = aws_iam_policy.lambda-allow-logs.arn
}

# allow audit-github to log to x-ray
resource "aws_iam_role_policy_attachment" "lambda-audit-github-xray" {
  count = var.lambda_audit_github_enabled

  role       = aws_iam_role.lambda-audit-github[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# == Lambda: audit-aws ==
resource "aws_lambda_function" "audit-aws" {
  count = var.lambda_audit_aws_enabled

  s3_bucket = module.s3_shared_uw2.buckets["lambda-functions"]
  s3_key    = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

  lifecycle {
    ignore_changes = [
      s3_key,
      last_modified,
    ]
  }

  function_name = "audit-aws"
  description   = "18F/identity-lambda-functions: AwsIamAuditor -- auditor of AWS IAM users and 2FA setup"
  role          = aws_iam_role.lambda-audit-aws[0].arn
  handler       = "main.IdentityAudit::AwsIamAuditor.process"
  runtime       = "ruby2.5"
  timeout       = 30 # seconds

  environment {
    variables = {
      #DEBUG = "1"
      DEBUG     = ""
      LOG_LEVEL = "0"
    }
  }

  tags = {
    source_repo = "https://github.com/18F/identity-lambda-functions"
  }
}

# Alert on errors
module "audit-aws-alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=0290e16a1789f986721a722337b6a9166bcebbc6"

  enabled              = var.lambda_audit_aws_enabled
  function_name        = var.lambda_audit_aws_enabled == 1 ? aws_lambda_function.audit-aws[0].function_name : ""
  alarm_actions        = [var.slack_events_sns_hook_arn]
  error_rate_threshold = 1 # percent
}

resource "aws_iam_role" "lambda-audit-aws" {
  count = var.lambda_audit_aws_enabled

  name = "lambda-audit-aws"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

resource "aws_iam_role_policy" "lambda-audit-aws-policy" {
  count = var.lambda_audit_aws_enabled

  name = "lambda-audit-aws-policy"
  role = aws_iam_role.lambda-audit-aws[0].id

  # Allow accessing necessary secrets
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/lambda/audit-github-token*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:GetLoginProfile",
                "iam:ListMFADevices",
                "iam:ListAccessKeys",
                "iam:ListSigningCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ses:SendRawEmail",
            "Resource": "*"
        }
    ]
}
EOM

}

# allow audit-aws to send logs
resource "aws_iam_role_policy_attachment" "lambda-audit-aws-logs" {
  count = var.lambda_audit_aws_enabled

  role       = aws_iam_role.lambda-audit-aws[0].name
  policy_arn = aws_iam_policy.lambda-allow-logs.arn
}

# allow audit-aws to log to x-ray
resource "aws_iam_role_policy_attachment" "lambda-audit-aws-xray" {
  count = var.lambda_audit_aws_enabled

  role       = aws_iam_role.lambda-audit-aws[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# Create some useful timer events
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every-hour"
  description         = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_rule" "weekdays_at_noon" {
  name                = "weekdays-at-noon"
  description         = "Fires on weekdays at 12p EST / 1 pm EDT"
  schedule_expression = "cron(0 17 ? * MON-FRI *)"
}

# Run the audit-github lambda daily on weekdays
resource "aws_cloudwatch_event_target" "audit-github_daily" {
  count = var.lambda_audit_github_enabled

  rule = aws_cloudwatch_event_rule.weekdays_at_noon.name
  arn  = aws_lambda_function.audit-github[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_audit-github" {
  count = var.lambda_audit_github_enabled

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit-github[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekdays_at_noon.arn
}

# Run the audit-aws lambda daily on weekdays
resource "aws_cloudwatch_event_target" "audit-aws_daily" {
  count = var.lambda_audit_aws_enabled

  rule = aws_cloudwatch_event_rule.weekdays_at_noon.name
  arn  = aws_lambda_function.audit-aws[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_audit-aws" {
  count = var.lambda_audit_aws_enabled

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit-aws[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekdays_at_noon.arn
}

# Create a common policy for lambdas to allow pushing logs to CloudWatch Logs.
# Ideally we would scope these more finely to only allow writing to aws/lambda/name-of-lambda.
resource "aws_iam_policy" "lambda-allow-logs" {
  name        = "lambda-allow-logs-tf"
  path        = "/"
  description = "Policy allowing lambdas to log to CloudWatch log groups starting with 'aws/lambda/'"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:/aws/lambda/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:/aws/lambda/*:log-stream:*"
            ]
        }
    ]
}
EOF

}

# TODO
# Resource": [
#   "arn:aws:logs:us-west-2:894947205914:log-group:/aws/lambda/test_function_jp:*"
# ]
