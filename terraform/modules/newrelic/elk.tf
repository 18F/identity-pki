# These alerts can be turned on for an environment by setting the newrelic_alerts_enabled variable to 1

resource "newrelic_nrql_alert_condition" "es_cluster_red" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: elasticsearch status is red"
  description = "Alert when the ES cluster in ${var.env_name} is red"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#problems-with-elasticsearch"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT count(*) from ElasticSearchHealthSample where label.environment = '${var.env_name}' and es_status = 'red'"
    evaluation_offset = 3
  }

  critical {
    operator      = "above"
    threshold     = 1
    threshold_duration      = 300
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "es_cluster_yellow" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.low[0].id
  name        = "${var.env_name}: elasticsearch status is yellow"
  description = "Alert when the ES cluster in ${var.env_name} is yellow"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#problems-with-elasticsearch"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT count(*) from ElasticSearchHealthSample where label.environment = '${var.env_name}' and es_status = 'yellow'"
    evaluation_offset = 3
  }

  critical {
    operator      = "above"
    threshold     = 1
    threshold_duration      = 300
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "es_no_logs" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: elasticsearch low log volume"
  description = "Alert when the ${var.env_name} ES cluster has unusually low log volume"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#problems-with-elasticsearch"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT average(es_documents_in_last_ten_minutes) from LogstashHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator      = "below"
    threshold     = var.events_in_last_ten_minutes_alert_threshold
    threshold_duration      = 120
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "es_low_disk_space" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.low[0].id
  name        = "${var.env_name}: elasticsearch low disk space"
  description = "Alert when nodes in the ${var.env_name} ES cluster are low on disk space"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#disk-space-woes"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT max(es_diskpercentused) from ElasticSearchHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator      = "above"
    threshold     = 70
    threshold_duration      = 300
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "es_critical_disk_space" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: elasticsearch critical disk space"
  description = "Alert when nodes in the ${var.env_name} ES cluster are critically low on disk space"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#disk-space-woes"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT max(es_diskpercentused) from ElasticSearchHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator      = "above"
    threshold     = 85
    threshold_duration      = 300
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "no_es_metrics" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: no metrics coming from elasticsearch"
  description = "Alert when there are no metrics coming from the ${var.env_name} ES cluster"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-alerting.html#setting-up-new-custom-metrics-to-send-to-newrelic"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT count(*) from ElasticSearchHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "below"
    threshold             = 1
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "no_logstash_metrics" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: no metrics coming from logstash"
  description = "Alert when there are no metrics coming from the ${var.env_name} logstash host: logstash host may be down"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-alerting.html#setting-up-new-custom-metrics-to-send-to-newrelic"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT count(*) from LogstashHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "below"
    threshold             = 1
    threshold_duration    = 840
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "no_log_archives" {
  count = var.elk_enabled
  policy_id = newrelic_alert_policy.high[0].id
  name        = "${var.env_name}: no ELK log files being archived"
  description = "Alert when there are no logs being archived to the s3 log archival bucket in ${var.env_name}: logstash host may be down"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/devops-elk.html#how-to-reindex-from-archived-data"
  enabled     = true
  value_function = "single_value"
  violation_time_limit = "TWELVE_HOURS"

  nrql {
    query       = "SELECT latest(logstash_files_archived_to_s3_in_last_ten_minutes) from LogstashArchiveHealthSample where label.environment = '${var.env_name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "below"
    threshold             = 2
    threshold_duration    = 840
    threshold_occurrences = "ALL"
  }
}
