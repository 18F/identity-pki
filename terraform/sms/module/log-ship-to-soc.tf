module "log-ship-to-soc-pinpoint-logs" {
  source                              = "../../modules/log_ship_to_soc"
  region                              = data.aws_region.current.name
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    (aws_cloudwatch_log_group.pinpoint_event_logger.name) = ""
  }
  env_name            = "sms-${var.env}-${data.aws_region.current.name}"
  soc_destination_arn = "arn:aws:logs:${data.aws_region.current.name}:752281881774:destination:elp-sms-lg-${data.aws_region.current.name}"
}
