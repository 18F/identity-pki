
module "newrelic" {
  # once we go to terraform 0.13.x, we will be able to do this
  # count = var.newrelic_alerts_enabled
  source = "../modules/newrelic/"

  enabled       = var.newrelic_alerts_enabled
  www_enabled   = var.www_newrelic_alerts_enabled
  elk_enabled   = var.elk_newrelic_alerts_enabled
  idp_enabled   = var.idp_newrelic_alerts_enabled
  enduser_enabled   = var.idp_enduser_newrelic_alerts_enabled
  dashboard_enabled = var.apps_enabled
  region        = var.region
  env_name      = var.env_name
  events_in_last_ten_minutes_threshold = var.events_in_last_ten_minutes_threshold
  root_domain   = var.root_domain
  pivcac_threshold   = var.pivcac_threshold
  web_threshold      = var.web_threshold
  web_warn_threshold = var.web_warn_threshold
  opsgenie_key_file  = var.opsgenie_key_file
}
