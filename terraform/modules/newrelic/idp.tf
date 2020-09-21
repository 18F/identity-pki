# These monitor the idp and pivcac services.
# enable these with setting these to 1:
#   var.enabled (turns on devops idp alerting)
#   var.dashboard_enabled (if the dashboard is there, alrt on it too)
#   var.enduser_enabled (enable alerts for the enduser team)

locals {
  # In prod, the TLS cert has only "secure.<domain>"
  # In other environments, the TLS cert has "idp.<env>.<domain>" and "<env>.<domain>"
  idp_domain_name = var.env_name == "prod" ? "secure.${var.root_domain}" : "idp.${var.env_name}.${var.root_domain}"
}

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

resource "newrelic_alert_condition" "low_apdex" {
  count       = var.enabled
  policy_id   = newrelic_alert_policy.businesshours[0].id
  name        = "${var.env_name}: Apdex low"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "apdex"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = var.apdex_threshold
    time_function = "all"
  }
}

resource "newrelic_alert_condition" "error_rate" {
  count = var.enabled
  policy_id = newrelic_alert_policy.businesshours[0].id
  name        = "${var.env_name}: High idp error rate"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "error_percentage"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = var.error_threshold
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

resource "newrelic_synthetics_monitor" "dashboard" {
  count = var.dashboard_enabled
  name = "${var.env_name} dashboard site monitor"
  type = "SIMPLE"
  frequency = 5
  status = "ENABLED"
  locations = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri                       = "https://dashboard.${var.env_name}.${var.root_domain}/"
  validation_string         = "Use the dashboard to manage your login.gov test integrations."
  verify_ssl                = true
}
resource "newrelic_synthetics_alert_condition" "dashboard" {
  count = var.dashboard_enabled
  policy_id = newrelic_alert_policy.businesshours[0].id

  name        = "https://dashboard.${var.env_name}.${var.root_domain}/ ping failure"
  monitor_id  = newrelic_synthetics_monitor.dashboard[0].id
}


resource "newrelic_synthetics_monitor" "api_health" {
  count = var.enabled
  name = "${var.env_name} /api/health check"
  type = "SIMPLE"
  frequency = 5
  status = "ENABLED"
  locations = ["AWS_US_EAST_1", "AWS_US_EAST_2"]

  uri                       = "https://${local.idp_domain_name}/api/health"
  validation_string         = "\"all_checks_healthy\":true"
  verify_ssl                = true
}
resource "newrelic_synthetics_alert_condition" "api_health" {
  count = var.www_enabled
  policy_id = newrelic_alert_policy.businesshours[0].id

  name        = "https://${local.idp_domain_name}/ ping failure"
  monitor_id  = newrelic_synthetics_monitor.api_health[0].id
}

resource "newrelic_alert_condition" "enduser_datastore_slow_queries" {
  count = var.enduser_enabled
  policy_id = newrelic_alert_policy.enduser[0].id
  name        = "${var.env_name}: All datastores slow queries"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "user_defined"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]
  user_defined_metric = "Datastore/all"
  user_defined_value_function = "max"

  term {
    duration      = 10
    operator      = "above"
    priority      = "critical"
    threshold     = var.datastore_threshold
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
  count = var.enduser_enabled
  policy_id = newrelic_alert_policy.enduser[0].id
  name        = "${var.env_name}: Response time is too high"
  enabled     = true
  description = "Alerting when the 95th percentile of transaction response times are over 2s, warn when it's over 1s."
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query = "SELECT percentile(duration, 95) FROM Transaction  WHERE appName = '${var.env_name}.${var.root_domain}'"
    evaluation_offset = 3
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

# # alert created by mhenke, commented out until he refines the query a bit more and makes a runbook
# resource "newrelic_nrql_alert_condition" "proofing_flow_errors" {
#   count = var.enabled
#   policy_id = newrelic_alert_policy.high[0].id
#   name        = "${var.env_name}: high rate of errors in proofing flow"
#   enabled     = true
#   description = "Alerting when errors in proofing flow get above 5% in the past 5 minutes"
#   value_function = "single_value"
#   runbook_url = "XXX"
#   violation_time_limit = "TWELVE_HOURS"

#   nrql {
#     query = "SELECT percentage(count(*), WHERE error is true and name LIKE 'Controller/idv/%' and appName = '${var.env_name}.${var.root_domain}') FROM Transaction WHERE name LIKE 'Controller/idv/%' and appName = '${var.env_name}.${var.root_domain}' FACET name"
#     evaluation_offset = 3
#   }

#   critical {
#     operator              = "above"
#     threshold             = 5
#     threshold_duration    = 300
#     threshold_occurrences = "at_least_once"
#   }
# }

resource "newrelic_alert_condition" "enduser_error_percentage" {
  count = var.enduser_enabled
  policy_id = newrelic_alert_policy.enduser[0].id
  name        = "${var.env_name}: Error percentage is too high"
  enabled     = true
  type        = "apm_app_metric"
  metric      = "error_percentage"
  condition_scope = "application"
  entities        = [data.newrelic_entity.idp[0].application_id]

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = var.error_threshold
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

resource "newrelic_dashboard" "error_dashboard" {
  count = var.enabled
  title = "Errors for ${var.error_dashboard_site}"
  editable = "read_only"

  widget {
    title = "Errors by Service Provider"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET service_provider WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
    row = 1
    column = 1
    width = 1
  }

 widget {
    title = "Errors by Endpoint"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET transactionName WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
    row = 1
    column = 2
    width = 1
  }

 widget {
    title = "Errors by IAL level"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET CASES (WHERE transactionName LIKE 'Controller/idv/%' AS IAL2, WHERE transactionName NOT LIKE 'Controller/idv/%' AS IAL1) WHERE appName = '${var.error_dashboard_site}' TIMESERIES"
    row = 2
    column = 1
    width = 1
  }

 widget {
    title = "Errors Count"
    visualization = "facet_table"
    nrql = "SELECT COUNT(*), uniques(error.message) FROM TransactionError WHERE appName = '${var.error_dashboard_site}' FACET error.class"
    row = 2
    column = 2
    width = 2
  }
}
