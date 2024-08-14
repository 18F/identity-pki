# Lambda IAM Resources

resource "aws_iam_policy" "lambda_to_redshift" {
  name = "${var.env_name}_lambda_to_redshift"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRedshiftExecutions"
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials",
          "redshift:GetClusterCredentialsWithIAM",
          "redshift-data:ExecuteStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:DescribeStatement",
          "redshift-data:ListStatements",
        ]
        Resource = [
          "*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_to_s3" {
  name = "${var.env_name}_lambda_to_s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Actions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.analytics_import.arn}/*"
        ]
      },
      {
        Sid    = "AllowKMSDecryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "db_consumption" {
  name = "${var.env_name}_db_consumption"
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

resource "aws_iam_policy" "db_consumption_lambda_to_cloudwatch" {
  name = "${var.env_name}_db_consumption_lambda_to_cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          join(":", [
            "arn:aws:logs:${var.region}",
            "${data.aws_caller_identity.current.account_id}:log-group",
            "/aws/lambda/${aws_lambda_function.db_consumption.function_name}:*"
          ])

        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "db_consumption_redshift" {
  role       = aws_iam_role.db_consumption.id
  policy_arn = aws_iam_policy.lambda_to_redshift.arn
}

resource "aws_iam_role_policy_attachment" "db_consumption_s3" {
  role       = aws_iam_role.db_consumption.id
  policy_arn = aws_iam_policy.lambda_to_s3.arn
}

resource "aws_iam_role_policy_attachment" "db_consumption_cloudwatch" {
  role       = aws_iam_role.db_consumption.id
  policy_arn = aws_iam_policy.db_consumption_lambda_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "db_consumption_insights" {
  role       = aws_iam_role.db_consumption.id
  policy_arn = data.aws_iam_policy.insights.arn
}
