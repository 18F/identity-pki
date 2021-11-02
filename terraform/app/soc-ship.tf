module "soc-ship" {
  source                              = "../modules/soc_ship"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "lg-log-ship-to-soc"
  cloudwatch_log_group_name           = var.cloudwatch_log_group_name
  env_name                            = var.env_name
  soc_destination_arn                 = var.soc_destination_arn
}
