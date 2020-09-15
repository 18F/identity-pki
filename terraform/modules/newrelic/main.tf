# this file sets up newrelic alerts for metrics
# Once we get tf 0.13.* going, we can get rid of all the count and [0] silliness

# NOTE:  these s3 objects need to be uploaded with --content-type text/plain

# This is a key that starts with NRAA
# see https://registry.terraform.io/providers/newrelic/newrelic/latest/docs#argument-reference
# This is created on https://rpm.newrelic.com/accounts/{accountID}/integrations?page=api_keys
data "aws_s3_bucket_object" "newrelic_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_apikey"
}

# This is a key that starts with NRAK.
# See https://registry.terraform.io/providers/newrelic/newrelic/latest/docs#argument-reference
# You can create this by going to https://account.newrelic.com/accounts/{accountID}/users/{yourUserID}
# and clicking on the API tab and creating a key.
data "aws_s3_bucket_object" "newrelic_admin_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_admin_apikey"
}

# This is the NewRelic account ID
# see https://registry.terraform.io/providers/newrelic/newrelic/latest/docs#argument-reference
data "aws_s3_bucket_object" "newrelic_account_id" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_account_id"
}

provider "newrelic" {
  version = ">= 2.1.2"
  region = "US"
  account_id = data.aws_s3_bucket_object.newrelic_account_id.body
  api_key = data.aws_s3_bucket_object.newrelic_apikey.body
  admin_api_key = data.aws_s3_bucket_object.newrelic_admin_apikey.body
}

data "aws_caller_identity" "current" {}

resource "newrelic_alert_policy" "high" {
  count = var.enabled
  name = "alert-high-${var.env_name}"
}

resource "newrelic_alert_policy" "low" {
  count = var.enabled
  name = "alert-low-${var.env_name}"
}

# Creates an opsgenie alert channel.
# NOTE:  This apikey needs to be uploaded with --content-type text/plain
data "aws_s3_bucket_object" "opsgenie_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_apikey"
}

resource "newrelic_alert_channel" "opsgenie" {
  count = var.enabled
  name = "opsgenie-channel-${var.env_name}"
  type = "opsgenie"

  config {
    api_key    = data.aws_s3_bucket_object.opsgenie_apikey.body
    tags       = "${var.env_name} environment"
    region     = "US"
  }
}

# Creates a Slack alert channel.
# NOTE:  These slack secrets need to be uploaded with --content-type text/plain
data "aws_s3_bucket_object" "slackchannel" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackchannel"
}
data "aws_s3_bucket_object" "slackwebhook" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackwebhook"
}

resource "newrelic_alert_channel" "slack" {
  count = var.enabled
  name = "slack-channel-${var.env_name}"
  type = "slack"

  config {
    channel = data.aws_s3_bucket_object.slackchannel.body
    url     = data.aws_s3_bucket_object.slackwebhook.body
  }
}

# Applies the created channels above to the alert policy
# referenced at the top of the config.
resource "newrelic_alert_policy_channel" "low" {
  count = var.enabled
  policy_id  = newrelic_alert_policy.low[0].id
  channel_ids = [
    newrelic_alert_channel.slack[0].id
  ]
}

# Applies the created channels above to the alert policy
# referenced at the top of the config.
resource "newrelic_alert_policy_channel" "high" {
  count = var.enabled
  policy_id  = newrelic_alert_policy.high[0].id
  channel_ids = [
    newrelic_alert_channel.opsgenie[0].id,
    newrelic_alert_channel.slack[0].id
  ]
}


# Below here are various alert conditions that will get sent to the configured alert channels

resource "newrelic_nrql_alert_condition" "es_cluster_red" {
  count = var.enabled
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
  count = var.enabled
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
  count = var.enabled
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
    threshold     = var.events_in_last_ten_minutes_threshold
    threshold_duration      = 120
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "es_low_disk_space" {
  count = var.enabled
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
  count = var.enabled
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
  count = var.enabled
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
  count = var.enabled
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
  count = var.enabled
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

data "newrelic_synthetics_monitor" "wwwlogingov" {
  count = var.www_enabled
  name = "${var.env_name} www.login.gov monitor"
}

data "newrelic_synthetics_monitor" "logingov" {
  count = var.www_enabled
  name = "${var.env_name} login.gov static site monitor"
}

resource "newrelic_synthetics_alert_condition" "wwwlogingov" {
  count = var.www_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name        = "https://www.login.gov ping failure"
  monitor_id  = data.newrelic_synthetics_monitor.wwwlogingov[0].id
}

resource "newrelic_synthetics_alert_condition" "logingov" {
  count = var.www_enabled
  policy_id = newrelic_alert_policy.high[0].id

  name        = "https://login.gov ping failure"
  monitor_id  = data.newrelic_synthetics_monitor.logingov[0].id
}
