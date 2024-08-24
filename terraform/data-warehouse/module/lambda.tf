locals {
  lambda_insights            = "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
  db_consumption_lambda_name = "${var.env_name}-db-consumption"
}

module "db_consumption_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "db_consumption.py"
  source_dir           = "${path.module}/lambda/consumption/"
  zip_filename         = "${path.module}/lambda/db_consumption.zip"
}

resource "aws_lambda_function" "db_consumption" {
  filename         = module.db_consumption_code.zip_output_path
  function_name    = local.db_consumption_lambda_name
  description      = ""
  role             = aws_iam_role.db_consumption.arn
  handler          = "db_consumption.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900 # in seconds, 15 minutes
  source_code_hash = module.db_consumption_code.zip_output_base64sha256

  layers = [
    local.lambda_insights
  ]

  logging_config {
    log_group  = aws_cloudwatch_log_group.db_consumption.name
    log_format = "Text"
  }

  environment {
    variables = {
      IAM_ROLE         = aws_iam_role.redshift_role.arn
      REDSHIFT_CLUSTER = aws_redshift_cluster.redshift.cluster_identifier
    }
  }
}

resource "aws_s3_bucket_notification" "s3_trigger_to_lambdas" {
  bucket = aws_s3_bucket.analytics_import.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.db_consumption.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "logs/"
    filter_suffix       = ".csv"
  }
  lambda_function {
    lambda_function_arn = aws_lambda_function.db_consumption.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "public/"
    filter_suffix       = ".csv"
  }
}

module "db_consumption_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=54aa8c603736993da0b4e7e93a64d749e95f4907"
  #source = "../../../../identity-terraform/lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.db_consumption.function_name
  alarm_actions        = local.low_priority_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.db_consumption.timeout
  runbook              = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting"
}

resource "aws_lambda_permission" "db_consumption_allow_s3_events" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowInvokeFromS3"
  function_name = aws_lambda_function.db_consumption.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.analytics_import.arn
}
