# this file sets up newrelic alerts for metrics
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    newrelic = {
      source = "newrelic/newrelic"
    }
  }
  required_version = ">= 0.13"
}

data "aws_caller_identity" "current" {}

resource "newrelic_alert_policy" "high" {
  name = "alert-high-${var.env_name}"
}

resource "newrelic_alert_policy" "low" {
  name = "alert-low-${var.env_name}"
}

resource "newrelic_alert_policy" "businesshours" {
  name = "alert-businesshours-${var.env_name}"
}

resource "newrelic_alert_policy" "enduser" {
  count = var.enduser_enabled
  name = "alert-enduser-${var.env_name}"
}

resource "newrelic_alert_policy_channel" "low" {
  policy_id  = newrelic_alert_policy.low.id
  channel_ids = [
    newrelic_alert_channel.slack.id
  ]
}

resource "newrelic_alert_policy_channel" "high" {
  policy_id  = newrelic_alert_policy.high.id
  channel_ids = [
    newrelic_alert_channel.opsgenie.id,
    newrelic_alert_channel.slack.id
  ]
}

resource "newrelic_alert_policy_channel" "businesshours" {
  policy_id  = newrelic_alert_policy.businesshours.id
  channel_ids = [
    newrelic_alert_channel.opsgenie_low.id,
    newrelic_alert_channel.slack.id
  ]
}

resource "newrelic_alert_policy_channel" "enduser" {
  count = var.enduser_enabled
  policy_id  = newrelic_alert_policy.enduser[0].id
  channel_ids = [
    newrelic_alert_channel.opsgenie_enduser[0].id
  ]
}

# Creates an opsgenie alert channel.
# NOTE:  This apikey needs to be uploaded with --content-type text/plain
data "aws_s3_bucket_object" "opsgenie_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/${var.opsgenie_key_file}"
}
resource "newrelic_alert_channel" "opsgenie" {
  name = "opsgenie-channel-${var.env_name}"
  type = "opsgenie"

  config {
    api_key    = data.aws_s3_bucket_object.opsgenie_apikey.body
    tags       = "${var.env_name} environment"
    region     = "US"
  }
}

data "aws_s3_bucket_object" "opsgenie_low_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_low_apikey"
}
resource "newrelic_alert_channel" "opsgenie_low" {
  name = "opsgenie-low-channel-${var.env_name}"
  type = "opsgenie"

  config {
    api_key    = data.aws_s3_bucket_object.opsgenie_low_apikey.body
    tags       = "${var.env_name} environment"
    region     = "US"
  }
}

data "aws_s3_bucket_object" "opsgenie_enduser_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_enduser_apikey"
}
resource "newrelic_alert_channel" "opsgenie_enduser" {
  count = var.enduser_enabled
  name = "opsgenie-enduser-channel-${var.env_name}"
  type = "opsgenie"

  config {
    api_key    = data.aws_s3_bucket_object.opsgenie_enduser_apikey.body
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
  name = "slack-channel-${var.env_name}"
  type = "slack"

  config {
    channel = data.aws_s3_bucket_object.slackchannel.body
    url     = data.aws_s3_bucket_object.slackwebhook.body
  }
}

