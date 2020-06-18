# this file sets up newrelic alerts for metrics
# Once we get tf 0.13.* going, we can get rid of all the count and [0] silliness

provider "newrelic" {}
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
data "aws_s3_bucket_object" "opsgenie_apikey" {
  count = var.enabled
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/opsgenie_apikey"
}

resource "newrelic_alert_channel" "opsgenie" {
  count = var.enabled
  name = "opsgenie-channel-${var.env_name}"
  type = "opsgenie"

  config {
    api_key = data.aws_s3_bucket_object.opsgenie_apikey[0].body
    region = "US"
# teams - (Optional) A set of teams for targeting notifications. Multiple values are comma separated.
# tags - (Optional) A set of tags for targeting notifications. Multiple values are comma separated.
# recipients - (Optional) A set of recipients for targeting notifications. Multiple values are comma separated.
  }
}

# Creates a Slack alert channel.
data "aws_s3_bucket_object" "slackchannel" {
  count = var.enabled
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackchannel"
}
data "aws_s3_bucket_object" "slackwebhook" {
  count = var.enabled
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackwebhook"
}

resource "newrelic_alert_channel" "slack" {
  count = var.enabled
  name = "slack-channel-${var.env_name}"
  type = "slack"

  config {
    channel = data.aws_s3_bucket_object.slackchannel[0].body
    url     = data.aws_s3_bucket_object.slackwebhook[0].body
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

  name        = "${var.env_name}_es_cluster_red"
  type        = "static"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/appdev-troubleshooting-production.html#ssh-into-the-elk-server"
  enabled     = true

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = "1"
    time_function = "all"
  }

  nrql {
    query       = "SELECT count(*) from ElasticSearchHealthSample where label.environment = '${var.env_name}' and es_status = 'red'"
    since_value = "3"
  }

  value_function = "single_value"
}

resource "newrelic_nrql_alert_condition" "es_cluster_yellow" {
  count = var.enabled
  policy_id = newrelic_alert_policy.low[0].id

  name        = "${var.env_name}_es_cluster_yellow"
  type        = "static"
  runbook_url = "https://login-handbook.app.cloud.gov/articles/appdev-troubleshooting-production.html#ssh-into-the-elk-server"
  enabled     = true

  term {
    duration      = 5
    operator      = "above"
    priority      = "critical"
    threshold     = "1"
    time_function = "all"
  }

  nrql {
    query       = "SELECT count(*) from ElasticSearchHealthSample where label.environment = '${var.env_name}' and es_status = 'yellow'"
    since_value = "3"
  }

  value_function = "single_value"
}
