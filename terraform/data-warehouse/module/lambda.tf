locals {
  lambda_insights            = "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
  db_consumption_lambda_name = "${var.env_name}-db-consumption"
  stale_data_check_name      = "${var.env_name}-stale-data-check"
}

module "db_consumption_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "db_consumption.py"
  source_dir           = "${path.module}/lambda/consumption/"
  zip_filename         = "${path.module}/lambda/db_consumption.zip"
}

module "stale_data_check_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "stale_data_check.py"
  source_dir           = "${path.module}/lambda/data_checks/"
  zip_filename         = "${path.module}/lambda/stale_data_check.zip"
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

resource "aws_lambda_function" "stale_data_check" {
  filename         = module.stale_data_check_code.zip_output_path
  function_name    = local.stale_data_check_name
  description      = "Lambda function to compare table stats between Redshift and IDP database stats in S3"
  role             = aws_iam_role.stale_data_check.arn
  handler          = "stale_data_check.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900 # in seconds, 15 minutes
  source_code_hash = module.stale_data_check_code.zip_output_base64sha256

  layers = [
    local.lambda_insights
  ]

  logging_config {
    log_group  = aws_cloudwatch_log_group.stale_data_check.name
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
  lambda_function {
    lambda_function_arn = aws_lambda_function.stale_data_check.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "table_summary_stats/"
    filter_suffix       = ".json"
  }
}

module "stale_data_check_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../../../../identity-terraform/lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.stale_data_check.function_name
  alarm_actions        = local.low_priority_alarm_actions
  ok_actions           = local.low_priority_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  treat_missing_data   = "notBreaching"
  duration_setting     = aws_lambda_function.stale_data_check.timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  error_rate_alarm_name_override   = "${var.env_name}-analytics-lambda-staleDataCheck-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-analytics-lambda-staleDataCheck-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-analytics-lambda-staleDataCheck-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${aws_lambda_function.stale_data_check.function_name} lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${aws_lambda_function.stale_data_check.function_name} lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${aws_lambda_function.stale_data_check.memory_size} MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${aws_lambda_function.stale_data_check.function_name} lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${aws_lambda_function.stale_data_check.timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}

module "db_consumption_alerts" {
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../../../../identity-terraform/lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.db_consumption.function_name
  alarm_actions        = local.low_priority_alarm_actions
  ok_actions           = local.low_priority_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  treat_missing_data   = "notBreaching"
  duration_setting     = aws_lambda_function.db_consumption.timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  error_rate_alarm_name_override   = "${var.env_name}-analytics-lambda-dbConsumption-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-analytics-lambda-dbConsumption-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-analytics-lambda-dbConsumption-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${aws_lambda_function.db_consumption.function_name} lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${aws_lambda_function.db_consumption.function_name} lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${aws_lambda_function.db_consumption.memory_size} MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${aws_lambda_function.db_consumption.function_name} lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${aws_lambda_function.db_consumption.timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}

resource "aws_lambda_permission" "db_consumption_allow_s3_events" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowInvokeFromS3"
  function_name = aws_lambda_function.db_consumption.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.analytics_import.arn
}

resource "aws_lambda_permission" "stale_data_check_allow_s3_events" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowInvokeFromS3"
  function_name = aws_lambda_function.stale_data_check.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.analytics_import.arn
}