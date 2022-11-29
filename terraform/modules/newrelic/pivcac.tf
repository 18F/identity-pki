# These monitor the pivcac services.
# enable these with setting these to 1:
#   var.enabled (turns on devops pivcac alerting)
#   var.enduser_enabled (enable alerts for the enduser team)

locals {
  pivcac_domain_name = "synthetics-expiration-check.pivcac.${var.env_name}.${var.root_domain}"
}

data "newrelic_entity" "pivcac" {
  count  = var.idp_enabled
  name   = "pivcac.${var.env_name}.${var.root_domain}"
  domain = "APM"
  type   = "APPLICATION"
}

resource "newrelic_alert_condition" "pivcac_low_throughput" {
  count           = var.idp_enabled
  policy_id       = newrelic_alert_policy.high[0].id
  name            = "${var.env_name}: PIVCAC LOW Throughput (web)"
  runbook_url     = "https://github.com/18F/identity-devops/wiki/Runbook:-low-throughput-in-New-Relic"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "throughput_web"
  condition_scope = "application"
  entities        = [data.newrelic_entity.pivcac[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.pivcac_low_traffic_alert_threshold
    time_function = "all"
  }
}

resource "newrelic_synthetics_monitor" "pivcac_certs_health_7d" {
  count             = var.idp_enabled
  name              = "${var.env_name} PIV/CAC /api/health/certs check (7 days)"
  type              = "SIMPLE"
  period            = "EVERY_HOUR"
  status            = "ENABLED"
  locations_public  = ["AWS_US_EAST_1", "AWS_US_EAST_2"]
  uri               = "https://${local.pivcac_domain_name}/api/health/certs.json?deadline=7d&source=newrelic"
  validation_string = "\"healthy\":true"
  verify_ssl        = true
}

resource "newrelic_synthetics_monitor" "pivcac_certs_health_30d" {
  count             = var.idp_enabled
  name              = "${var.env_name} PIV/CAC /api/health/certs check (30 days)"
  type              = "SIMPLE"
  period            = "EVERY_HOUR"
  status            = "ENABLED"
  locations_public  = ["AWS_US_EAST_1", "AWS_US_EAST_2"]
  uri               = "https://${local.pivcac_domain_name}/api/health/certs.json?deadline=30d&source=newrelic"
  validation_string = "\"healthy\":true"
  verify_ssl        = true
}

resource "newrelic_synthetics_alert_condition" "pivcac_certs_health_7d" {
  count     = var.idp_enabled
  policy_id = newrelic_alert_policy.low[0].id

  name       = "${var.env_name} certs expiring failure"
  monitor_id = newrelic_synthetics_monitor.pivcac_certs_health_7d[0].id
}

resource "newrelic_synthetics_alert_condition" "pivcac_certs_health_30d" {
  count     = var.idp_enabled
  policy_id = newrelic_alert_policy.low[0].id

  name       = "${var.env_name} certs expiring failure"
  monitor_id = newrelic_synthetics_monitor.pivcac_certs_health_30d[0].id
}