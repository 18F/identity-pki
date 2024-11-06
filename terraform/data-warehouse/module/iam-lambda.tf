# Lambda IAM Resources

resource "aws_iam_policy" "lambda_to_redshift" {
  name = "${var.env_name}_lambda_to_redshift"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetRedshiftClusterInformation"
        Effect = "Allow"
        Action = [
          "redshift:DescribeClusters",
        ]
        Resource = [
          "*"
        ]
      },
      {
        Sid    = "GetRedshiftCredentials"
        Effect = "Allow"
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:GetClusterCredentialsWithIAM",
        ]
        Resource = [
          # This constructs the specific database ARN that the lambda is allowed to access.
          # When a data resource or provider specific implementation is available, we should migrate to that. 
          "${replace(aws_redshift_cluster.redshift.arn, ":cluster:", ":dbname:")}/${aws_redshift_cluster.redshift.database_name}"
        ]
        Condition = {
          "StringEquals" = {
            "redshift:DbName" : aws_redshift_cluster.redshift.database_name
          }
        }
      },
      {
        Sid    = "AllowRedshiftExecutions"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
        ]
        Resource = [
          aws_redshift_cluster.redshift.arn
        ]
      },
      {
        Sid    = "GetRedshiftExecutionsResults"
        Effect = "Allow"
        Action = [
          "redshift-data:GetStatementResult",
          "redshift-data:DescribeStatement",
          "redshift-data:ListStatements",
        ]
        Resource = [
          "*"
        ]
        Condition = {
          "StringEquals" = {
            "redshift-data:statement-owner-iam-userid" : "$${aws:userid}"
          }
        }
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
  name        = "${var.env_name}_db_consumption"
  description = "Enables the minimal permissions needed for the AWS Lambda db consumption function to update AWS Redshift tables from csv files written to AWS S3."
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

resource "aws_iam_role" "stale_data_check" {
  name        = "${var.env_name}_stale_data_check"
  description = "Enables the minimal permissions needed for the AWS Lambda stale data check function to validate the freshness of data in AWS Redshift."
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
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "${aws_cloudwatch_log_group.db_consumption.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "stale_data_check_to_cloudwatch" {
  name = "${var.env_name}_stale_data_check_to_cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "${aws_cloudwatch_log_group.stale_data_check.arn}:*"
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

resource "aws_iam_role_policy_attachment" "stale_data_check_redshift" {
  role       = aws_iam_role.stale_data_check.id
  policy_arn = aws_iam_policy.lambda_to_redshift.arn
}

resource "aws_iam_role_policy_attachment" "stale_data_check_s3" {
  role       = aws_iam_role.stale_data_check.id
  policy_arn = aws_iam_policy.lambda_to_s3.arn
}

resource "aws_iam_role_policy_attachment" "stale_data_check_cloudwatch" {
  role       = aws_iam_role.stale_data_check.id
  policy_arn = aws_iam_policy.stale_data_check_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "stale_data_check_insights" {
  role       = aws_iam_role.stale_data_check.id
  policy_arn = data.aws_iam_policy.insights.arn
}