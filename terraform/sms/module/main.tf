data "aws_caller_identity" "current" {}

module "log-ship-to-soc-pinpoint-logs" {
  source                              = "../../modules/log_ship_to_soc"
  region                              = data.aws_region.current.name
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "${var.env}-pinpoint-logs" = ""
  }
  env_name            = "sms-${var.env}-${data.aws_region.current.name}"
  soc_destination_arn = "arn:aws:logs:${data.aws_region.current.name}:752281881774:destination:elp-sms-lg-${data.aws_region.current.name}"
}
