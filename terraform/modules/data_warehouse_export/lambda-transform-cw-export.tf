resource "aws_lambda_permission" "transform_cw_export_s3_events" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowInvokeFromS3"
  function_name = aws_lambda_function.transform_cw_export.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.analytics_export.arn
}

module "transform_cw_export_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  # source = "../../../../identity-terraform/null_archive"
  source_code_filename = "transform_cw_export.py"
  source_dir           = "${path.module}/lambda/transform_cw_export/"
  zip_filename         = "${path.module}/lambda/transform_cw_export.zip"

}

resource "aws_lambda_function" "transform_cw_export" {
  filename         = module.transform_cw_export_code.zip_output_path
  source_code_hash = module.transform_cw_export_code.zip_output_base64sha256
  function_name    = local.transform_cw_export_lambda_name
  description      = "Transforms Cloudwatch Exports to CSV for consumption in analytics account"
  role             = aws_iam_role.transform_cw_export.arn
  handler          = "transform_cw_export.lambda_handler"
  runtime          = "python3.9"
  memory_size      = var.transform_cw_export_memory_size
  timeout          = var.data_warehouse_export_lambda_timeout # in seconds, 15 minutes

  layers = [
    local.lambda_insights
  ]

  tags = {
    environment = var.env_name
  }

  environment {
    variables = {
      LOG_GROUPS = jsonencode([
        for log_group in local.analytics_target_log_groups : { name = log_group.resource.name, json_encoded = log_group.json_encoded }
      ])
    }
  }

}

resource "aws_iam_role" "transform_cw_export" {
  name               = "${local.transform_cw_export_lambda_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_role_policy" "transform" {
  role   = aws_iam_role.transform_cw_export.id
  policy = data.aws_iam_policy_document.transform_cw_export.json
}

data "aws_iam_policy_document" "transform_cw_export" {
  statement {
    sid    = "TransformationPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListObjectsv2",
    ]

    resources = [
      aws_s3_bucket.analytics_export.arn,
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
  }
  statement {
    sid    = "GetLogStreamData"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
    ]
    resources = [
      for log_group in local.analytics_target_log_groups : "${log_group.resource.arn}:log-stream:"
    ]
  }
  statement {
    sid    = "LogInvocationsToCloudwatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${local.transform_cw_export_lambda_name}:*"
    ]
  }
}

