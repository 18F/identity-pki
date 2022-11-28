# These monitor the dashboard services
# enable these with setting these to 1:
#   var.enabled (turns on devops idp alerting)
#   var.dashboard_enabled (if the dashboard is there, alert on it too)
#   var.enduser_enabled (enable alerts for the enduser team)

data "newrelic_entity" "dashboard" {
  count  = var.dashboard_enabled
  name   = "dashboard.${var.env_name}.${var.root_domain}"
  domain = "APM"
  type   = "APPLICATION"
}

resource "newrelic_alert_condition" "dashboard_low_throughput" {
  count           = var.dashboard_enabled
  policy_id       = newrelic_alert_policy.low[0].id
  name            = "${var.env_name}: DASHBOARD LOW Throughput (web)"
  runbook_url     = "https://github.com/18F/identity-devops/wiki/Runbook:-low-throughput-in-New-Relic"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "throughput_web"
  condition_scope = "application"
  entities        = [data.newrelic_entity.dashboard[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.web_low_traffic_alert_threshold
    time_function = "all"
  }
}

resource "newrelic_synthetics_monitor" "dashboard" {
  count            = var.dashboard_enabled
  name             = "${var.env_name} dashboard site monitor"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri               = "https://dashboard.${var.env_name}.${var.root_domain}/"
  validation_string = "Use the dashboard to manage your Login.gov test integrations."
  verify_ssl        = true
}

resource "newrelic_synthetics_alert_condition" "dashboard" {
  count     = var.dashboard_enabled
  policy_id = newrelic_alert_policy.low[0].id

  name       = "https://dashboard.${var.env_name}.${var.root_domain}/ availability check failure"
  monitor_id = newrelic_synthetics_monitor.dashboard[0].id
}

resource "newrelic_alert_condition" "dashboard_error_rate" {
  count           = var.dashboard_enabled
  policy_id       = newrelic_alert_policy.low[0].id
  name            = "${var.env_name}: High dashboard error rate"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "error_percentage"
  condition_scope = "application"
  entities        = [data.newrelic_entity.dashboard[0].application_id]

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = var.error_alert_threshold
    time_function = "all"
  }

  term {
    duration      = 5
    operator      = "above"
    priority      = "warning"
    threshold     = var.error_warn_threshold
    time_function = "all"
  }
}
