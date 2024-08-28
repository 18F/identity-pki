module "start_cw_export_task_alerts" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=54aa8c603736993da0b4e7e93a64d749e95f4907"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.start_cw_export_task[count.index].function_name
  alarm_actions        = local.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.start_cw_export_task[count.index].timeout
  runbook              = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting"
}

module "transform_cw_export_alerts" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=54aa8c603736993da0b4e7e93a64d749e95f4907"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.transform_cw_export[count.index].function_name
  alarm_actions        = local.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.transform_cw_export[count.index].timeout
  runbook              = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting"
}

module "start_dms_task_alerts" {
  count  = var.enable_dms_analytics ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_alerts?ref=54aa8c603736993da0b4e7e93a64d749e95f4907"
  #source = "../lambda_alerts"

  enabled              = 1
  function_name        = aws_lambda_function.start_dms_task[count.index].function_name
  alarm_actions        = local.low_priority_dw_alarm_actions
  error_rate_threshold = 0 # percent
  error_rate_operator  = "GreaterThanThreshold"
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.start_dms_task[count.index].timeout
  runbook              = "Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting"
}

resource "aws_cloudwatch_metric_alarm" "dms_filter_columns_alarm" {
  count = var.enable_dms_analytics ? 1 : 0

  alarm_name                = "${var.env_name}-dms-filter-columns-failure"
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
  alarm_actions             = local.low_priority_dw_alarm_actions
  alarm_description         = <<EOM
An error has occured for the DMS task: ${aws_dms_replication_task.filtercolumns[count.index].replication_task_id}

Runbook: https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-Data-Warehouse-Alerts-Troubleshooting
EOM
}
