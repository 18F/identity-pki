
module "newrelic" {
  # once we go to terraform 0.13.x, we will be able to do this
  # count = var.newrelic_alerts_enabled
  source = "../modules/newrelic/"

  enabled                                    = var.newrelic_alerts_enabled
  staticsite_alerts_enabled                  = var.staticsite_newrelic_alerts_enabled
  elk_enabled                                = var.elk_newrelic_alerts_enabled
  idp_enabled                                = var.idp_newrelic_alerts_enabled
  enduser_enabled                            = var.idp_enduser_newrelic_alerts_enabled
  dashboard_enabled                          = var.dashboard_newrelic_alerts_enabled
  region                                     = var.region
  env_name                                   = var.env_name
  events_in_last_ten_minutes_alert_threshold = var.events_in_last_ten_minutes_alert_threshold
  root_domain                                = var.root_domain
  pivcac_alert_threshold                     = var.pivcac_alert_threshold
  web_alert_threshold                        = var.web_alert_threshold
  web_warn_threshold                         = var.web_warn_threshold
  opsgenie_key_file                          = var.opsgenie_key_file
  error_dashboard_site                       = "${var.env_name}.${var.root_domain}"
}
