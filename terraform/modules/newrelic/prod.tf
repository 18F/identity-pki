# These are meant to be enabled in prod only, so that the static
# sites are monitored there.  Enable these by setting www_enabled to 1.

resource "newrelic_synthetics_monitor" "wwwlogingov" {
  count = var.www_enabled
  name = "${var.env_name} www.login.gov monitor"
  type = "SIMPLE"
  frequency = 5
  status = "ENABLED"
  locations = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri                       = "https://www.login.gov"
  validation_string         = "secure access to government services"
  verify_ssl                = true
}

resource "newrelic_synthetics_monitor" "logingov" {
  count = var.www_enabled
  name = "${var.env_name} login.gov static site monitor"
  type = "SIMPLE"
  frequency = 5
  status = "ENABLED"
  locations = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri                       = "https://login.gov"
  validation_string         = "secure access to government services"
  verify_ssl                = true
}

resource "newrelic_synthetics_alert_condition" "wwwlogingov" {
  count = var.www_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name        = "https://www.login.gov ping failure"
  monitor_id  = newrelic_synthetics_monitor.wwwlogingov[0].id
}

resource "newrelic_synthetics_alert_condition" "logingov" {
  count = var.www_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name        = "https://login.gov ping failure"
  monitor_id  = newrelic_synthetics_monitor.logingov[0].id
}
