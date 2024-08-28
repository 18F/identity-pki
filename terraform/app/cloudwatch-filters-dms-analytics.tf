resource "aws_cloudwatch_log_metric_filter" "dms_filter_columns_metric" {
  count = var.enable_dms_analytics ? 1 : 0

  name           = "${var.env_name}-dms-filter-columns-error"
  pattern        = "Cannot refresh source table"
  log_group_name = module.dms[count.index].dms_log_group
  metric_transformation {
    name      = "${var.env_name}-dms-filter-columns-error"
    namespace = "${var.env_name}/dms"
    value     = 1
  }
}
