variable "lambda_identity_lambda_functions_gitrev" {
  default = "07af04c7bb53fde03ed9a705953b1881490d8c05"
  description = "Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform)"
}
variable "lambda_audit_github_enabled" {
  default = 1
  description = "Whether to run the audit-github lambda in this account"
}
variable "lambda_audit_github_debug" {
  default = 1
  description = "Whether to run the audit-github lambda in debug mode in this account"
}
variable "lambda_audit_aws_enabled" {
  default = 1
  description = "Whether to run the audit-aws lambda in this account"
}

# == Lambda: audit-github ==
resource "aws_lambda_function" "audit-github" {
  count = "${var.lambda_audit_github_enabled}"

  s3_bucket        = "${aws_s3_bucket.lambda-functions.id}"
  s3_key           = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

  lifecycle {
    ignore_changes = ["s3_key", "last_modified"]
  }

  function_name    = "audit-github"
  description      = "18F/identity-lambda-functions: GithubAuditor -- auditor of Github teams and membership"
  role             = "${aws_iam_role.lambda-audit-github.arn}"
  handler          = "main.Functions::GithubAuditHandler.process"
  runtime          = "ruby2.5"
  timeout          = 30 # seconds

  environment {
    variables = {
      #DEBUG = "1"
      DEBUG = "${var.lambda_audit_github_debug ? "1" : ""}"
      LOG_LEVEL = "0"
    }
  }

  tags {
    source_repo = "https://github.com/18F/identity-lambda-functions"
  }
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
  name = "lambda-audit-github"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}
resource aws_iam_role_policy "lambda-audit-github-policy" {
  name = "lambda-audit-github-policy"
  role = "${aws_iam_role.lambda-audit-github.id}"

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
  role       = "${aws_iam_role.lambda-audit-github.name}"
  policy_arn = "${aws_iam_policy.lambda-allow-logs.arn}"
}
# allow audit-github to log to x-ray
resource "aws_iam_role_policy_attachment" "lambda-audit-github-xray" {
  role       = "${aws_iam_role.lambda-audit-github.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# == Lambda: audit-aws ==
resource "aws_lambda_function" "audit-aws" {
  count = "${var.lambda_audit_aws_enabled}"

  s3_bucket        = "${aws_s3_bucket.lambda-functions.id}"
  s3_key           = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

  lifecycle {
    ignore_changes = ["s3_key", "last_modified"]
  }

  function_name    = "audit-aws"
  description      = "18F/identity-lambda-functions: AwsIamAuditor -- auditor of AWS IAM users and 2FA setup"
  role             = "${aws_iam_role.lambda-audit-aws.arn}"
  handler          = "main.Functions::AWSAuditHandler.process"
  runtime          = "ruby2.5"
  timeout          = 30 # seconds

  environment {
    variables = {
      #DEBUG = "1"
      DEBUG = ""
      LOG_LEVEL = "0"
    }
  }

  tags {
    source_repo = "https://github.com/18F/identity-lambda-functions"
  }
}

resource "aws_iam_role" "lambda-audit-aws" {
  name = "lambda-audit-aws"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}
resource aws_iam_role_policy "lambda-audit-aws-policy" {
  name = "lambda-audit-aws-policy"
  role = "${aws_iam_role.lambda-audit-aws.id}"

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
  role       = "${aws_iam_role.lambda-audit-aws.name}"
  policy_arn = "${aws_iam_policy.lambda-allow-logs.arn}"
}
# allow audit-aws to log to x-ray
resource "aws_iam_role_policy_attachment" "lambda-audit-aws-xray" {
  role       = "${aws_iam_role.lambda-audit-aws.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}



# Create some useful timer events
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name = "every-five-minutes"
  description = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}
resource "aws_cloudwatch_event_rule" "every_hour" {
  name = "every-hour"
  description = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}
resource "aws_cloudwatch_event_rule" "weekdays_at_noon" {
  name = "weekdays-at-noon"
  description = "Fires on weekdays at 12p EST / 1 pm EDT"
  schedule_expression = "cron(0 16 ? * MON-FRI *)"
}

# Run the audit-github lambda daily on weekdays
resource "aws_cloudwatch_event_target" "audit-github_daily" {
    rule = "${aws_cloudwatch_event_rule.weekdays_at_noon.name}"
    arn = "${aws_lambda_function.audit-github.arn}"
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_audit-github" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.audit-github.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.weekdays_at_noon.arn}"
}

# Run the audit-aws lambda daily on weekdays
resource "aws_cloudwatch_event_target" "audit-aws_daily" {
    rule = "${aws_cloudwatch_event_rule.weekdays_at_noon.name}"
    arn = "${aws_lambda_function.audit-aws.arn}"
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_audit-aws" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.audit-aws.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.weekdays_at_noon.arn}"
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
