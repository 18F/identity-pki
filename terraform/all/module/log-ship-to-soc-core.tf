# For new AWS accounts you MUST contact the SOCaaS team to allow this account
# permission to the destination ARN.
# See: https://github.com/18F/identity-devops/wiki/Runbook:-GSA-SOC-as-a-Service-(SOCaaS)#cloudwatch-shipping-important-note
module "log-ship-to-soc-cloudtrail-logs" {
  source                              = "../../modules/log_ship_to_soc"
  region                              = var.region
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "CloudTrail/DefaultLogGroup" = ""
  }
  env_name            = "account"
  soc_destination_arn = "arn:aws:logs:${var.region}:752281881774:destination:elp-cloudtrail-lg"
}
