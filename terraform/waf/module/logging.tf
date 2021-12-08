
resource "aws_cloudwatch_log_group" "cw_waf_logs" {
  name              = "aws-waf-logs-${local.web_acl_name}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  name            = "log-ship-to-soc"
  log_group_name  = aws_cloudwatch_log_group.cw_waf_logs.name
  filter_pattern  = ""
  destination_arn = var.soc_destination_arn
  distribution    = "ByLogStream"
  role_arn        = aws_iam_role.cloudwatch_logs_role.arn
}

