module "start_cw_export_task_alerts" {

  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.start_cw_export_task.function_name
  alarm_actions        = var.low_priority_dw_alarm_actions
  ok_actions           = var.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  treat_missing_data   = "notBreaching"
  duration_setting     = aws_lambda_function.start_cw_export_task.timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  error_rate_alarm_name_override   = "${var.env_name}-idp-lambda-startCwExport-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-idp-lambda-startCwExport-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-idp-lambda-startCwExport-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${aws_lambda_function.start_cw_export_task.function_name} lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${aws_lambda_function.start_cw_export_task.function_name} lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${aws_lambda_function.start_cw_export_task.memory_size} MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${aws_lambda_function.start_cw_export_task.function_name} lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${aws_lambda_function.start_cw_export_task.timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}

module "transform_cw_export_alerts" {

  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.transform_cw_export.function_name
  alarm_actions        = var.low_priority_dw_alarm_actions
  ok_actions           = var.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  treat_missing_data   = "notBreaching"
  duration_setting     = aws_lambda_function.transform_cw_export.timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  error_rate_alarm_name_override   = "${var.env_name}-idp-lambda-transformCwExport-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-idp-lambda-transformCwExport-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-idp-lambda-transformCwExport-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${aws_lambda_function.transform_cw_export.function_name} lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${aws_lambda_function.transform_cw_export.function_name} lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${aws_lambda_function.transform_cw_export.memory_size} MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${aws_lambda_function.transform_cw_export.function_name} lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${aws_lambda_function.transform_cw_export.timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}

module "start_dms_task_alerts" {

  source = "github.com/18F/identity-terraform//lambda_alerts?ref=a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.start_dms_task.function_name
  alarm_actions        = var.low_priority_dw_alarm_actions
  ok_actions           = var.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  treat_missing_data   = "notBreaching"
  duration_setting     = aws_lambda_function.start_dms_task.timeout
  runbook              = local.data_warehouse_lambda_alerts_runbooks

  error_rate_alarm_name_override   = "${var.env_name}-idp-lambda-startDmsTask-errorDetected"
  memory_usage_alarm_name_override = "${var.env_name}-idp-lambda-startDmsTask-memoryUsageHigh"
  duration_alarm_name_override     = "${var.env_name}-idp-lambda-startDmsTask-durationLong"
  memory_usage_threshold           = var.data_warehouse_memory_usage_threshold
  duration_threshold               = var.data_warehouse_duration_threshold

  error_rate_alarm_description = <<EOM
One or more errors were detected running the ${aws_lambda_function.start_dms_task.function_name} lambda function.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  memory_usage_alarm_description = <<EOM
The memory used by the ${aws_lambda_function.start_dms_task.function_name} lambda function, exceeded ${var.data_warehouse_memory_usage_threshold}% of the ${aws_lambda_function.start_dms_task.memory_size}  MB limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM

  duration_alarm_description = <<EOM
The runtime of the ${aws_lambda_function.start_dms_task.function_name} lambda function exceeded ${var.data_warehouse_duration_threshold}% of the ${aws_lambda_function.start_dms_task.timeout / 60} minute limit configured.

${local.data_warehouse_lambda_alerts_runbooks}
EOM
}

resource "aws_cloudwatch_metric_alarm" "dms_filter_columns_alarm" {


  alarm_name                = "${var.env_name}-idp-dms-filterColumnsTask-errorDetected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = "${var.env_name}-dms-filter-columns-error"
  namespace                 = "${var.env_name}/dms"
  period                    = 1800 # 30 minute period
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = var.low_priority_dw_alarm_actions
  ok_actions                = var.low_priority_dw_alarm_actions
  alarm_description         = <<EOM
One or more errors occurred running the DMS replication task id - "${aws_dms_replication_task.filtercolumns.replication_task_id}."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#dms-task-failure-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "s3_replication_failed_operations_analytics" {

  alarm_name          = "${var.env_name}-idp-s3-toAnalyticsAccount-replicationFailed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "OperationsFailedReplication"
  namespace           = "AWS/S3"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = <<EOM
The S3 replication failed for the "login-gov-analytics-export" bucket.

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#s3-replication-alerts
EOM

  dimensions = {
    RuleId            = aws_s3_bucket_replication_configuration.to_analytics.rule[0].id
    BucketName        = aws_s3_bucket.analytics_export.id
    SourceBucket      = aws_s3_bucket.analytics_export.id
    DestinationBucket = split(":", local.analytics_import_arn)[5]
    StorageType       = "AllStorageTypes"
  }

  alarm_actions = var.low_priority_dw_alarm_actions
  ok_actions    = var.low_priority_dw_alarm_actions

  actions_enabled = true
}

resource "aws_cloudwatch_metric_alarm" "sensitive_column_compare_alarm" {

  alarm_name                = "${var.env_name}-idp-dms-columnCompareTask-sensitive-errorDetected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = aws_cloudwatch_log_metric_filter.dms_sensitive_column_compare_metric.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.dms_sensitive_column_compare_metric.metric_transformation[0].namespace
  period                    = 1800 # 30 minute period
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = var.low_priority_dw_alarm_actions
  ok_actions                = var.low_priority_dw_alarm_actions
  alarm_description         = <<EOM
One or more errors occurred running the Colum Compare Task - "${module.column_compare_task.function_name}."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#dms-column-compare-task-alerts
EOM
}

resource "aws_cloudwatch_metric_alarm" "nonsensitive_column_compare_alarm" {

  alarm_name                = "${var.env_name}-idp-dms-columnCompareTask-nonsensitive-errorDetected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = aws_cloudwatch_log_metric_filter.dms_nonsensitive_column_compare_metric.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.dms_nonsensitive_column_compare_metric.metric_transformation[0].namespace
  period                    = 1800 # 30 minute period
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  alarm_actions             = var.low_priority_dw_alarm_actions
  ok_actions                = var.low_priority_dw_alarm_actions
  alarm_description         = <<EOM
One or more errors occurred running the Colum Compare Task - "${module.column_compare_task.function_name}."

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting#dms-task-failure-alerts
EOM
}

