module "waf_mrg_update_notify" {
  count  = var.enable_waf_mrg_update_notifications ? 1 : 0
  source = "../../modules/waf_mrg_updates/"
  providers = {
    aws = aws.use1
  }
  sns_to_slack = data.aws_sns_topic.alert_warning.arn
}