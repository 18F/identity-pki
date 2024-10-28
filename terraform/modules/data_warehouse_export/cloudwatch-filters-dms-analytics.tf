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
