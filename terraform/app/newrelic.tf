
module "newrelic" {
  source = "../modules/newrelic/"

  enabled                              = var.newrelic_alerts_enabled
  staticsite_alerts_enabled            = var.staticsite_newrelic_alerts_enabled
  idp_enabled                          = var.idp_newrelic_alerts_enabled
  pager_alerts_enabled                 = var.new_relic_pager_alerts_enabled
  enduser_enabled                      = var.idp_enduser_newrelic_alerts_enabled
  dashboard_enabled                    = var.dashboard_newrelic_alerts_enabled
  cdn_idp_static_assets_alarms_enabled = var.cdn_idp_static_assets_newrelic_alarms_enabled
  region                               = var.region
  env_name                             = var.env_name
  pivcac_low_traffic_alert_threshold   = var.pivcac_low_traffic_alert_threshold
  root_domain                          = var.root_domain
  web_low_traffic_alert_threshold      = var.web_low_traffic_alert_threshold
  web_low_traffic_warn_threshold       = var.web_low_traffic_warn_threshold
  opsgenie_key_file                    = var.opsgenie_key_file
  error_dashboard_site                 = "${var.env_name}.${var.root_domain}"
  memory_free_threshold_byte           = var.memory_free_threshold_byte
  low_memory_alert_enabled             = var.low_memory_alert_enabled
}
