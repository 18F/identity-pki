# These monitor the idp and pivcac services.
# enable these with setting these to 1:
#   var.enabled (turns on devops idp/pivcac alerting)
#   var.dashboard_enabled (if the dashboard is there, alert on it too)
#   var.enduser_enabled (enable alerts for the enduser team)

locals {
  # In prod, the TLS cert has only "secure.<domain>"
  # In other environments, the TLS cert has "idp.<env>.<domain>" and "<env>.<domain>"
  idp_domain_name = var.env_name == "prod" ? "secure.${var.root_domain}" : "idp.${var.env_name}.${var.root_domain}"
}

data "newrelic_entity" "idp" {
  count  = var.idp_enabled
  name   = "${var.env_name}.${var.root_domain}"
  domain = "APM"
  type   = "APPLICATION"
}

resource "newrelic_alert_condition" "low_throughput" {
  count           = var.idp_enabled
  policy_id       = newrelic_alert_policy.high[0].id
  name            = "${var.env_name}: LOW Throughput (web)"
  runbook_url     = "https://github.com/18F/identity-devops/wiki/Runbook:-low-throughput-in-New-Relic"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "throughput_web"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.web_low_traffic_alert_threshold
    time_function = "all"
  }

  term {
    duration      = 5
    operator      = "below"
    priority      = "warning"
    threshold     = var.web_low_traffic_warn_threshold
    time_function = "all"
  }
}

resource "newrelic_alert_condition" "low_apdex" {
  count           = var.idp_enabled
  policy_id       = newrelic_alert_policy.high[0].id
  name            = "${var.env_name}: Apdex low"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "apdex"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.apdex_alert_threshold
    time_function = "all"
  }
}

resource "newrelic_alert_condition" "error_rate" {
  count           = var.idp_enabled
  policy_id       = newrelic_alert_policy.high[0].id
  name            = "${var.env_name}: High idp error rate"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "error_percentage"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

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

resource "newrelic_synthetics_monitor" "api_health" {
  count            = var.idp_enabled
  name             = "${var.env_name} /api/health check"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri               = "https://${local.idp_domain_name}/api/health"
  validation_string = "\"all_checks_healthy\":true"
  verify_ssl        = true
}
resource "newrelic_synthetics_alert_condition" "api_health" {
  count     = var.idp_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name       = "https://${local.idp_domain_name}/api/health failure"
  monitor_id = newrelic_synthetics_monitor.api_health[0].id
}

resource "newrelic_synthetics_monitor" "outbound_proxy_health" {
  count            = var.idp_enabled
  name             = "${var.env_name} /api/health/outbound check"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["AWS_US_EAST_1"]

  uri               = "https://${local.idp_domain_name}/api/health/outbound"
  validation_string = "\"healthy\":true"
  verify_ssl        = true
}
resource "newrelic_synthetics_alert_condition" "outbound_proxy_health" {
  count     = var.idp_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name       = "https://${local.idp_domain_name}/api/health/outbound failure"
  monitor_id = newrelic_synthetics_monitor.outbound_proxy_health[0].id
}

resource "newrelic_alert_condition" "enduser_datastore_slow_queries" {
  count                       = var.enduser_enabled
  policy_id                   = newrelic_alert_policy.enduser[0].id
  name                        = "${var.env_name}: Web datastores slow queries"
  enabled                     = true
  type                        = "apm_app_metric"
  metric                      = "user_defined"
  condition_scope             = "application"
  entities                    = [data.newrelic_entity.idp[0].application_id]
  user_defined_metric         = "Datastore/allWeb"
  user_defined_value_function = "max"

  term {
    duration      = 10
    operator      = "above"
    priority      = "critical"
    threshold     = var.datastore_alert_threshold
    time_function = "all"
  }

  term {
    duration      = 10
    operator      = "above"
    priority      = "warning"
    threshold     = var.datastore_warn_threshold
    time_function = "all"
  }
}

resource "newrelic_nrql_alert_condition" "enduser_response_time" {
  count                        = var.enduser_enabled
  policy_id                    = newrelic_alert_policy.enduser[0].id
  name                         = "${var.env_name}: Response time is too high"
  enabled                      = true
  description                  = "Alerting when the 95th percentile of transaction response times are over 2s, warn when it's over 1s."
  violation_time_limit_seconds = 43200
  aggregation_window           = 60
  aggregation_method           = "cadence"
  aggregation_delay            = 120

  nrql {
    query = "SELECT percentile(duration, 95) FROM Transaction  WHERE appName = '${var.env_name}.${var.root_domain}'"
  }

  critical {
    operator              = "above"
    threshold             = 2
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 1
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "controller_action_errors" {
  count                        = var.enduser_enabled
  policy_id                    = newrelic_alert_policy.enduser[0].id
  name                         = "${var.env_name}: high rate of errors in controller action"
  enabled                      = true
  description                  = "Alerting when errors in controller action name get above 0.5% for the past 2 minutes"
  runbook_url                  = "https://github.com/18F/identity-devops/wiki/Runbook:-controller-action-error-rate"
  violation_time_limit_seconds = 43200
  aggregation_window           = 60
  aggregation_method           = "event_flow"
  aggregation_delay            = 60

  nrql {
    query = "SELECT percentage(count(*), WHERE http.statusCode >= 500 and appName = '${var.env_name}.${var.root_domain}') FROM Transaction WHERE appName = '${var.env_name}.${var.root_domain}' FACET name"
  }

  critical {
    operator              = "above"
    threshold             = 0.5
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "service_provider_errors" {
  count       = var.enduser_enabled
  policy_id   = newrelic_alert_policy.enduser[0].id
  name        = "${var.env_name}: high rate of errors for service provider"
  enabled     = true
  description = "Alerting when errors for individual service provider get above 0.5% for the past 2 minutes"

  runbook_url                  = "https://github.com/18F/identity-devops/wiki/Runbook:-high-service-provider-error-rate"
  violation_time_limit_seconds = 43200
  aggregation_window           = 60
  aggregation_method           = "event_flow"
  aggregation_delay            = 60

  nrql {
    query = "SELECT percentage(count(*), WHERE error is true and http.statusCode >= 500 and appName = '${var.env_name}.${var.root_domain}') FROM Transaction WHERE appName = '${var.env_name}.${var.root_domain}' FACET service_provider"
  }

  critical {
    operator              = "above"
    threshold             = 0.5
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_alert_condition" "enduser_error_percentage" {
  count           = var.enduser_enabled
  policy_id       = newrelic_alert_policy.enduser[0].id
  name            = "${var.env_name}: Error percentage is too high"
  enabled         = true
  type            = "apm_app_metric"
  metric          = "error_percentage"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

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

resource "newrelic_one_dashboard" "error_dashboard" {
  count = var.idp_enabled

  name        = "Errors for ${var.error_dashboard_site}"
  permissions = "public_read_only"

  page {
    name = "Errors for ${var.error_dashboard_site}"

    widget_area {
      title  = "Errors by Service Provider"
      row    = 1
      column = 1
      height = 3
      width  = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET service_provider WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_area {
      title  = "Errors by Endpoint"
      row    = 1
      column = 5
      height = 3
      width  = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET transactionName WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_area {
      title  = "Errors by IAL level"
      row    = 4
      column = 1
      height = 3
      width  = 4

      nrql_query {
        account_id = 1376370
        query      = "SELECT count(*) FROM TransactionError FACET CASES (WHERE transactionName LIKE 'Controller/idv/%' AS IAL2, WHERE transactionName NOT LIKE 'Controller/idv/%' AS IAL1) WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
      }
    }

    widget_table {
      title  = "Errors Count"
      row    = 4
      column = 5
      height = 3
      width  = 8

      nrql_query {
        account_id = 1376370
        query      = "SELECT COUNT(*), uniques(error.message) FROM TransactionError WHERE appName = '${var.error_dashboard_site}' FACET error.class"
      }
    }
  }
}

resource "newrelic_synthetics_monitor" "cloudfront_health" {
  count            = (var.enabled + var.cdn_idp_static_assets_alarms_enabled) >= 2 ? 1 : 0
  name             = "${var.env_name} static /packs/manifest.json check"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri               = "https://${local.idp_domain_name}/packs/manifest.json"
  validation_string = "entrypoints"
  verify_ssl        = true
}
resource "newrelic_synthetics_alert_condition" "cloud_health" {
  count     = (var.enabled + var.cdn_idp_static_assets_alarms_enabled) >= 2 ? 1 : 0
  policy_id = newrelic_alert_policy.high[0].id

  name       = "https://${local.idp_domain_name}/packs/manifest.json health failure"
  monitor_id = newrelic_synthetics_monitor.cloudfront_health[0].id
}