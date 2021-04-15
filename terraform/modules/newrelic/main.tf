# this file sets up newrelic alerts for metrics
# Once we get tf 0.13.* going, we can get rid of all the count and [0] silliness
terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = ">= 2.21.0"
    }
  }
  required_version = ">= 0.13"
}

# NOTE:  these s3 objects need to be uploaded with --content-type text/plain

# This is a key that starts with NRAK.
# see https://docs.newrelic.com/docs/apis/get-started/intro-apis/new-relic-api-keys/#user-api-key
# This is created at https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher
data "aws_s3_bucket_object" "newrelic_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_apikey"
}

# This is the NewRelic account ID
# see https://registry.terraform.io/providers/newrelic/newrelic/latest/docs#argument-reference
data "aws_s3_bucket_object" "newrelic_account_id" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_account_id"
}

provider "newrelic" {
  region     = "US"
  account_id = data.aws_s3_bucket_object.newrelic_account_id.body
  api_key    = data.aws_s3_bucket_object.newrelic_apikey.body
}

data "aws_caller_identity" "current" {}

resource "newrelic_alert_policy" "high" {
  count = var.enabled
  name  = "alert-high-${var.env_name}"
}

resource "newrelic_alert_policy" "low" {
  count = var.enabled
  name  = "alert-low-${var.env_name}"
}

resource "newrelic_alert_policy" "businesshours" {
  count = var.enabled
  name  = "alert-businesshours-${var.env_name}"
}

resource "newrelic_alert_policy" "enduser" {
  count = var.enduser_enabled
  name  = "alert-enduser-${var.env_name}"
}

resource "newrelic_alert_policy_channel" "low" {
  count     = var.enabled
  policy_id = newrelic_alert_policy.low[0].id
  channel_ids = [
    newrelic_alert_channel.slack[0].id
  ]
}

resource "newrelic_alert_policy_channel" "high" {
  count     = var.enabled
  policy_id = newrelic_alert_policy.high[0].id
  channel_ids = [
    newrelic_alert_channel.opsgenie[0].id,
    newrelic_alert_channel.slack[0].id
  ]
}

resource "newrelic_alert_policy_channel" "businesshours" {
  count     = var.enabled
  policy_id = newrelic_alert_policy.businesshours[0].id
  channel_ids = [
    newrelic_alert_channel.opsgenie_low[0].id,
    newrelic_alert_channel.slack[0].id
  ]
}

resource "newrelic_alert_policy_channel" "enduser" {
  count     = var.enduser_enabled
  policy_id = newrelic_alert_policy.enduser[0].id
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
  count = var.enabled
  name  = "opsgenie-channel-${var.env_name}"
  type  = "opsgenie"

  config {
    api_key = data.aws_s3_bucket_object.opsgenie_apikey.body
    tags    = "${var.env_name} environment"
    region  = "US"
  }
}

data "aws_s3_bucket_object" "opsgenie_low_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_low_apikey"
}
resource "newrelic_alert_channel" "opsgenie_low" {
  count = var.enabled
  name  = "opsgenie-low-channel-${var.env_name}"
  type  = "opsgenie"

  config {
    api_key = data.aws_s3_bucket_object.opsgenie_low_apikey.body
    tags    = "${var.env_name} environment"
    region  = "US"
  }
}

data "aws_s3_bucket_object" "opsgenie_enduser_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_enduser_apikey"
}
resource "newrelic_alert_channel" "opsgenie_enduser" {
  count = var.enduser_enabled
  name  = "opsgenie-enduser-channel-${var.env_name}"
  type  = "opsgenie"

  config {
    api_key = data.aws_s3_bucket_object.opsgenie_enduser_apikey.body
    tags    = "${var.env_name} environment"
    region  = "US"
  }
}

# Creates a Slack alert channel.
# NOTE:  These slack secrets need to be uploaded with --content-type text/plain
data "aws_s3_bucket_object" "slackchannel" {
  count  = var.enabled
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackchannel"
}

data "aws_s3_bucket_object" "slackwebhook" {
  count  = var.enabled
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/slackwebhook"
}

resource "newrelic_alert_channel" "slack" {
  count = var.enabled
  name  = "slack-channel-${var.env_name}"
  type  = "slack"

  config {
    channel = data.aws_s3_bucket_object.slackchannel[count.index].body
    url     = data.aws_s3_bucket_object.slackwebhook[count.index].body
  }
}

