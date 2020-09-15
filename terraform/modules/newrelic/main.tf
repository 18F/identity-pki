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
