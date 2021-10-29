
locals {
  count = data.aws_caller_identity.current.account_id == "894947205914" ? 1 : 0
}

module "kinesis-firehose" {
  count                               = local.count
  source                              = "../modules/soc_ship"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "lg-log-ship-to-soc"
  cloudwatch_log_group_name           = ["CloudTrail/DefaultLogGroup"]
  cloudwatch_filter_pattern           = " "
  env_name                            = var.env_name
}
