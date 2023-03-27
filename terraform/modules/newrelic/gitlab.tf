locals {
  gitlab_url = var.env_name == "production" ? var.root_domain : "gitlab.${var.env_name}.${var.root_domain}"
}

resource "newrelic_synthetics_monitor" "gitlab_health" {
  count            = (var.enabled + var.gitlab_enabled) >= 2 ? 1 : 0
  name             = "${var.env_name} gitlab check"
  type             = "SIMPLE"
  period           = "EVERY_5_MINUTES"
  status           = "ENABLED"
  locations_public = ["US_EAST_2"]

  uri               = "https://${local.gitlab_url}"
  validation_string = "GitLab"
  verify_ssl        = true
}

resource "newrelic_nrql_alert_condition" "gitlab_health" {
  count                        = (var.enabled + var.gitlab_enabled) >= 2 ? 1 : 0
  policy_id                    = newrelic_alert_policy.low[0].id
  name                         = "${var.env_name} gitlab health failure for over 3 hours: Please check to see what broke the deployment, @login-devtools-oncall"
  violation_time_limit_seconds = 43200

  nrql {
    query = "SELECT count(*) FROM SyntheticCheck WHERE monitorName = '${var.env_name} gitlab check' AND result = 'FAILED'"
  }

  critical {
    operator              = "above"
    threshold             = 1
    threshold_duration    = 10800
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "disk_space_alert" {
  count                        = (var.enabled + var.gitlab_enabled) >= 2 ? 1 : 0
  policy_id                    = newrelic_alert_policy.low[0].id
  name                         = "${var.env_name}: GitLab LOW Disk Space Alert"
  violation_time_limit_seconds = 43200
  aggregation_window           = 60
  aggregation_method           = "cadence"
  aggregation_delay            = 120

  nrql {
    query = "from StorageSample SELECT min(diskFreePercent) where fullHostname like '%${var.env_name}.gitlab%'"
  }

  critical {
    operator              = "below"
    threshold             = 10
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "below"
    threshold             = 15
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}
