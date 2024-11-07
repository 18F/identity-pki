resource "aws_cloudwatch_log_metric_filter" "dms_filter_columns_metric" {
  name           = "${var.env_name}-dms-filter-columns-error"
  pattern        = "Cannot refresh source table"
  log_group_name = var.dms.dms_log_group
  metric_transformation {
    name      = "${var.env_name}-dms-filter-columns-error"
    namespace = "${var.env_name}/dms"
    value     = 1
  }
}

resource "aws_cloudwatch_log_metric_filter" "dms_sensitive_column_compare_metric" {
  name           = "${var.env_name}-sensitive-column-compare"
  pattern        = "Sensitive columns are in the DMS import rules"
  log_group_name = module.column_compare_task.log_group_name
  metric_transformation {
    name      = "${var.env_name}-sensitive-column-compare-task"
    namespace = "${var.env_name}/lambda"
    value     = 1
  }
}

resource "aws_cloudwatch_log_metric_filter" "dms_nonsensitive_column_compare_metric" {
  name           = "${var.env_name}-nonsensitive-column-compare"
  pattern        = "DMS Column Discrepancy"
  log_group_name = module.column_compare_task.log_group_name
  metric_transformation {
    name      = "${var.env_name}-nonsensitive-column-compare-task"
    namespace = "${var.env_name}/lambda"
    value     = 1
  }
}
