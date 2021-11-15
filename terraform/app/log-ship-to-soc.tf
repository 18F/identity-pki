locals {
  environment = var.env_name == "int" || var.env_name == "staging" || var.env_name == "prod" ? 1 : 0

}
module "log-ship-s3-soc-nonprod" {
  count                               = local.environment
  source                              = "../modules/log_ship_s3_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship"
  cloudwatch_log_group_name = {
    "${var.env_name}_flow_log_group"           = " "
    "${var.env_name}/dns/query"                = " "
    "${var.env_name}_/var/log/auth.log"        = " "
    "${var.env_name}_/var/log/audit/audit.log" = " "
    "${var.env_name}_/var/log/kern.log"        = " "
    "${var.env_name}_/var/log/messages"        = " "
    "${var.env_name}_/var/log/syslog"          = " "
  }
  env_name            = var.env_name
  soc_destination_arn = var.soc_destination_arn
}
