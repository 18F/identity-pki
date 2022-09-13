###Lambda###

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lambdafunction" {
  filename      = data.archive_file.lambdafunction.output_path
  function_name = "export-ses-logs-to-s3"
  role          = aws_iam_role.lambda_export_to_s3_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  description   = "Lambda exporting cloudwatch logs to S3"
  timeout       = "300"

  environment {
    variables = {
      S3_BUCKET   = var.s3_bucket
      CW_LogGroup = jsonencode(var.cw_log_group)
      AWS_ACCOUNT = data.aws_caller_identity.current.account_id
    }
  }
}

data "archive_file" "lambdafunction" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.py.zip"
}

data "aws_iam_policy_document" "lambdafunction_iam_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambdafunction_iam_lambda_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.export_cw_logs.arn}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:DescribeExportTasks"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_export_to_s3_role" {
  name               = "Exporttos3LambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambdafunction_iam_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "export_lambda" {
  role       = aws_iam_role.lambda_export_to_s3_role.name
  policy_arn = aws_iam_policy.lambdafunction_iam_lambda_policy.arn
}

####Cloudwatchlog group
resource "aws_cloudwatch_log_group" "export_cw_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambdafunction.function_name}"
  retention_in_days = 90
}

####IAM policy for CreateExportTask###
resource "aws_iam_policy" "lambdafunction_iam_lambda_policy_exportTask" {
  count = length(var.cw_log_group)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateExportTask"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.cw_log_group[count.index]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "export_lambda_second" {
  count      = length(aws_iam_policy.lambdafunction_iam_lambda_policy_exportTask)
  role       = aws_iam_role.lambda_export_to_s3_role.name
  policy_arn = aws_iam_policy.lambdafunction_iam_lambda_policy_exportTask[count.index].arn
}
