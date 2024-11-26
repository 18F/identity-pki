
module "column_compare_task" {

  source = "github.com/18F/identity-terraform//lambda_function?ref=6d514dc91b3a9ba000feb9ec05e83b5b8b734344"
  #source = "../../../../identity-terraform/lambda_function"

  # lambda function
  region               = var.region
  function_name        = "${var.env_name}-column-compare-task"
  description          = "Compare dms mapping rule json with idp sensitive column json"
  source_code_filename = "column_compare_task.py"
  source_dir           = "${path.module}/lambda/column_compare_task/"
  runtime              = "python3.12"
  error_rate_threshold = 0
  error_rate_operator  = "GreaterThanThreshold"
  insights_enabled     = true
  duration_setting     = var.data_warehouse_export_lambda_timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  environment_variables = {
    DMS_TASK_ARN = aws_dms_replication_task.filtercolumns.replication_task_arn
    S3_BUCKET    = aws_s3_bucket.idp_dw_tasks.id
  }

  # Logging and alarms
  cloudwatch_retention_days = var.cloudwatch_retention_days
  alarm_actions             = var.low_priority_dw_alarm_actions
  ok_actions                = var.low_priority_dw_alarm_actions
  treat_missing_data        = "notBreaching"

  # Lambda trigger (EventBridge event or schedule)
  # schedule_expression = "rate(1 day)"

  # IAM permissions
  lambda_iam_policy_document = data.aws_iam_policy_document.column_compare_task_policies.json

  error_rate_alarm_name_override   = "${var.env_name}-idp-lambda-columnCompareTask-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-idp-lambda-columnCompareTask-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-idp-lambda-columnCompareTask-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${var.env_name}-column-compare-task lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${var.env_name}-column-compare-task lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${var.column_compare_task_memory_size} MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${var.env_name}-column-compare-task lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${var.data_warehouse_export_lambda_timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}







