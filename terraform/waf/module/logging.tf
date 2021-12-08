
resource "aws_cloudwatch_log_group" "cw_waf_logs" {
  name              = "aws-waf-logs-${local.web_acl_name}"
  retention_in_days = 365
}

module "log-ship-to-soc-waf-logs" {
  source                              = "../../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    tostring(aws_cloudwatch_log_group.cw_waf_logs.name) = ""
  }
  env_name            = local.web_acl_name
  soc_destination_arn = var.soc_destination_arn
}

