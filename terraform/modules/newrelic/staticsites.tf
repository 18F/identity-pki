# These are meant to be enabled in prod only, so that the static
# sites are monitored there.  Enable these by setting staticsite_alerts_enabled to 1.

resource "newrelic_synthetics_monitor" "wwwlogingov" {
  count            = var.staticsite_alerts_enabled
  name             = "${var.env_name} www.login.gov monitor"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["US_EAST_1", "US_EAST_2"]

  uri               = "https://www.login.gov"
  validation_string = var.staticsite_fixed_string
  verify_ssl        = true
}

resource "newrelic_synthetics_monitor" "logingov" {
  count            = var.staticsite_alerts_enabled
  name             = "${var.env_name} login.gov static site monitor"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["US_EAST_1", "US_EAST_2"]

  uri               = "https://login.gov"
  validation_string = var.staticsite_fixed_string
  verify_ssl        = true
}

resource "newrelic_synthetics_alert_condition" "wwwlogingov" {
  count     = var.staticsite_alerts_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name       = "https://www.login.gov ping failure"
  monitor_id = newrelic_synthetics_monitor.wwwlogingov[0].id
}

resource "newrelic_synthetics_alert_condition" "logingov" {
  count     = var.staticsite_alerts_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name       = "https://login.gov ping failure"
  monitor_id = newrelic_synthetics_monitor.logingov[0].id
}

