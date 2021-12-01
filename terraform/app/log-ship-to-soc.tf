module "log-ship-to-soc-os-logs" {
  count                               = var.send_cw_to_soc
  source                              = "../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "${var.env_name}_/var/log/auth.log"        = ""
    "${var.env_name}_/var/log/audit/audit.log" = ""
    "${var.env_name}_/var/log/kern.log"        = ""
    "${var.env_name}_/var/log/messages"        = ""
    "${var.env_name}_/var/log/syslog"          = ""
  }
  env_name            = var.env_name
  soc_destination_arn = var.soc_destination_arn
}

### sending vpc flow logs to the vpc flow log endpoint
module "log-ship-to-soc-vpc-flow-log" {
  count                               = var.send_cw_to_soc
  source                              = "../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "${var.env_name}_flow_log_group" = ""
  }
  env_name            = "${var.env_name}-vpc"
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-flow-lg"
}

### sending dns query logs to the dns query log endpoint
module "log-ship-to-soc-dns-query-log" {
  count                               = var.send_cw_to_soc
  source                              = "../modules/log_ship_to_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "${var.env_name}/dns/query" = ""
  }
  env_name            = "${var.env_name}-dns"
  soc_destination_arn = "arn:aws:logs:us-west-2:752281881774:destination:elp-dns-lg"
}


