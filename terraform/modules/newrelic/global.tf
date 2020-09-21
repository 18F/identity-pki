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


# also set up some dashboards here, since this should only ever be enabled once
resource "newrelic_dashboard" "ELK" {
  count = var.www_enabled
  title = "ELK!"
  editable = "read_only"

  widget {
    title = "ELK log volume per environment"
    visualization = "faceted_line_chart"
    nrql = "SELECT average(es_documents_in_last_ten_minutes)/10 from LogstashHealthSample FACET label.environment TIMESERIES 2 minute"
    row = 1
    column = 1
    width = 1
  }

  widget {
    title = "Cloudtrail log volume per environment"
    visualization = "faceted_line_chart"
    nrql = "SELECT average(es_cloudtrail_documents_in_last_ten_minutes)/10 from LogstashHealthSample FACET label.environment TIMESERIES 2 minutes"
    row = 2
    column = 1
    width = 1
  }

  widget {
    title = "Elasticsearch Cluster Status"
    visualization = "facet_table"
    nrql = "SELECT latest(es_status) FROM ElasticSearchHealthSample FACET label.environment"
    row = 1
    column = 2
    height = 2
  }

  widget {
    title = "% Disk used on fullest node"
    visualization = "facet_table"
    nrql = "SELECT max(numeric(es_diskpercentused)) as 'disk % used' FROM ElasticSearchHealthSample since 10 minutes ago where es_diskpercentused IS NOT NULL facet label.environment"
    row = 1
    column = 3
    height = 2
  }

  widget {
    title = "Log message files archived to s3 in the last 10 minutes"
    visualization = "faceted_line_chart"
    nrql = "SELECT average(logstash_files_archived_to_s3_in_last_ten_minutes) from LogstashArchiveHealthSample where logstash_files_archived_to_s3_in_last_ten_minutes IS NOT NULL TIMESERIES 2 minutes FACET label.environment"
    row = 3
    column = 1
  }

  widget {
    title = "GB used for storing logs in ELK"
    visualization = "facet_bar_chart"
    nrql = "SELECT latest(es_total_logs_gb_disk_used) from LogstashHealthSample FACET label.environment"
    row = 3
    column = 2
  }

  widget {
    title = "Events currently stored in ELK"
    visualization = "facet_bar_chart"
    nrql = "SELECT latest(es_total_document_count) from LogstashHealthSample FACET label.environment"
    row = 3
    column = 3
  }
}

resource "newrelic_dashboard" "prod_errors" {
  count = var.www_enabled
  title = "Errors for ${var.error_dashboard_site}"
  editable = "read_only"

  widget {
    title = "Errors by Service Provider"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET service_provider WHERE entityGuid = 'MTM3NjM3MHxBUE18QVBQTElDQVRJT058NTIxMzY4NTg' AND appName = '${error_dashboard_site}' SINCE 6 hours ago TIMESERIES UNTIL now"
    row = 1
    column = 1
    width = 1
  }

 widget {
    title = "Errors by Endpoint"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET transactionName WHERE entityGuid = 'MTM3NjM3MHxBUE18QVBQTElDQVRJT058NTIxMzY4NTg' AND appName = '${error_dashboard_site}' SINCE 6 HOURS AGO TIMESERIES"
    row = 1
    column = 2
    width = 1
  }

 widget {
    title = "Errors by IAL level"
    visualization = "faceted_area_chart"
    nrql = "SELECT count(*) FROM TransactionError FACET CASES (WHERE transactionName LIKE 'Controller/idv/%' AS IAL2, WHERE transactionName NOT LIKE 'Controller/idv/%' AS IAL1) WHERE appName = '${error_dashboard_site}' SINCE 6 HOURS AGO TIMESERIES"
    row = 2
    column = 1
    width = 1
  }

 widget {
    title = "Errors Count"
    visualization = "facet_table"
    nrql = "SELECT COUNT(*), uniques(error.message) FROM TransactionError WHERE appName = '${error_dashboard_site}' FACET error.class SINCE 6 hours ago"
    row = 2
    column = 2
    width = 2
  }
}
