resource "aws_cloudwatch_log_metric_filter" "id_token_hint" {
  name           = "id_token_hint-use"
  log_group_name = aws_cloudwatch_log_group.idp_production.name
  pattern        = "id_token_hint="

  metric_transformation {
    name          = "id_token_hint-use"
    namespace     = "${var.env_name}/SpillDetectorMetrics"
    value         = "1"
    default_value = "0"
  }
}

