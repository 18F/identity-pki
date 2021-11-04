locals {
  count = data.aws_caller_identity.current.account_id == "894947205914" ? 1 : 0
}
module "log-ship-s3-soc" {
  count                               = local.count
  source                              = "../modules/log_ship_s3_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship"
  cloudwatch_log_group_name           = var.cloudwatch_log_group_name
  env_name                            = var.env_name
  soc_destination_arn                 = var.soc_destination_arn
}
