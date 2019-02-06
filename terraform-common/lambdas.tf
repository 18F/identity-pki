variable "lambda_audit_github_enabled" {
  default = 1
  description = "Whether to run the audit-github lambda in this account"
}
variable "lambda_identity_lambda_functions_gitrev" {
  default = "7a468f03d11e91ee0e680af396f7e3830272cd66"
  description = "Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform)"
}

resource "aws_lambda_function" "audit-github" {
  count = "${var.lambda_audit_github_enabled}"

  s3_bucket        = "${aws_s3_bucket.lambda-functions.id}"
  s3_key           = "circleci/identity-lambda-functions/${var.lambda_identity_lambda_functions_gitrev}.zip"

  function_name    = "audit-github"
  role             = "${aws_iam_role.lambda-audit-github.arn}"
  handler          = "main.Functions::GithubAuditHandler.process"
  runtime          = "ruby2.5"

  environment {
    variables = {
      foo = "bar"
      DEBUG = "1"
    }
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
        }
    ]
}
EOM
}
resource "aws_iam_role_policy_attachment" "lambda-audit-github-logs" {
  role       = "${aws_iam_role.lambda-audit-github.name}"
  policy_arn = "${aws_iam_policy.lambda-allow-logs.arn}"

}


# Create a common policy for lambdas to allow pushing logs to CloudWatch Logs.
resource "aws_iam_policy" "lambda-allow-logs" {
  name        = "lambda-allow-logs-tf"
  path        = "/"
  description = "Policy allowing lambdas to log to CloudWatch log groups starting with 'lambda/'"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:lambda/*"
    }
  ]
}
EOF
}
