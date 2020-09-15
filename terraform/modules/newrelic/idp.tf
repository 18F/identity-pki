# These monitor the idp and pivcac services.  To turn these alerts on,
# set idp_enabled to 1

data "newrelic_entity" "pivcac" {
  count = var.enabled
  name = "pivcac.${var.env_name}.${var.root_domain}"
  domain = "APM"
  type = "APPLICATION"
}

data "newrelic_entity" "idp" {
  count = var.enabled
  name = "${var.env_name}.${var.root_domain}"
  domain = "APM"
  type = "APPLICATION"
}

resource "newrelic_alert_condition" "pivcac_low_throughput" {
  count       = var.enabled
  policy_id   = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: PIVCAC LOW Throughput (web)"
  runbook_url = "https://github.com/18F/identity-private/wiki/Runbook:-low-throughput-in-New-Relic"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "throughput_web"
  condition_scope = "application"
  entities        = [data.newrelic_entity.pivcac[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.pivcac_threshold
    time_function = "all"
  }
}

resource "newrelic_alert_condition" "low_throughput" {
  count = var.enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: LOW Throughput (web)"
  runbook_url = "https://github.com/18F/identity-private/wiki/Runbook:-low-throughput-in-New-Relic"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "throughput_web"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.web_threshold
    time_function = "all"
  }

  term {
    duration      = 15
    operator      = "below"
    priority      = "warning"
    threshold     = var.web_warn_threshold
    time_function = "all"
  }
}
