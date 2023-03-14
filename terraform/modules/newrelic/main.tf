# this file sets up newrelic alerts for metrics
# Once we get tf 0.13.* going, we can get rid of all the count and [0] silliness

locals {
  opsgenie_payload_template = <<-EOF
{
  "message": {{json issueTitle}},
  "alias": {{json accumulations.conditionName.[0] }},
  "description": {{json issuePageUrl}},
  "responders":[{"id":"2fbef770-e306-488e-bbe2-76e2c860a2c7","type":"team"}]
}
EOF

  slack_low_payload_template = <<-EOF
{
    "text": "New Relic: *{{issueTitle}}*",
    "attachments": [{
        "fields": [{
                "title": "IssueID",
                "value": {{json issueId}}
            },
            {
                "title": "IssueURL",
                "value": {{json issuePageUrl}}
            },
            {
                "title": "NewRelic priority",
                "value": {{json priority}}
            },
            {
                "title": "Runbook",
                "value": "{{#each accumulations.runbookUrl}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Description",
                "value": "{{#each annotations.description}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Alert Policy Names",
                "value": "{{#each accumulations.policyName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Alert Condition Names",
                "value": "{{#each accumulations.conditionName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },            
            {
                "title": "Workflow Name",
                "value": {{json workflowName}}
            }
        ],
        "mrkdwn_in": ["text", "pretext"],
        "color": "#29A1E6"
    }]
}
EOF

  slack_high_payload_template = <<-EOF
{
    "text": "New Relic: *{{issueTitle}}* <!subteam^SUY1QMZE3>",
    "attachments": [{
        "fields": [{
                "title": "IssueID",
                "value": {{json issueId}}
            },
            {
                "title": "IssueURL",
                "value": {{json issuePageUrl}}
            },
            {
                "title": "NewRelic priority",
                "value": {{json priority}}
            },
            {
                "title": "Runbook",
                "value": "{{#each accumulations.runbookUrl}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Description",
                "value": "{{#each annotations.description}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Alert Policy Names",
                "value": "{{#each accumulations.policyName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },
            {
                "title": "Alert Condition Names",
                "value": "{{#each accumulations.conditionName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
            },            
            {
                "title": "Workflow Name",
                "value": {{json workflowName}}
            }
        ],
        "mrkdwn_in": ["text", "pretext"],
        "color": "#29A1E6"
    }]
}
EOF
}

data "aws_caller_identity" "current" {}

# This needs to be uploaded to S3 with --content-type text/plain
# This is a key that starts with NRAK ; created at https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher
# see https://docs.newrelic.com/docs/apis/get-started/intro-apis/new-relic-api-keys/#user-api-key
# NOTE:  This apikey needs to be uploaded with --content-type text/plain
data "aws_s3_object" "opsgenie_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/${var.opsgenie_key_file}"
}

data "aws_s3_object" "opsgenie_low_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_low_apikey"
}

data "aws_s3_object" "opsgenie_enduser_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_enduser_apikey"
}

data "aws_s3_object" "slack_low_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/otherevents_webhook_url"
}

data "aws_s3_object" "slack_high_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/events_webhook_url"
}

# Alert Policies
resource "newrelic_alert_policy" "low" {
  count = var.enabled
  name  = "alert-low-${var.env_name}"
}

resource "newrelic_alert_policy" "high" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "alert-high-${var.env_name}"
}

resource "newrelic_alert_policy" "in_person" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "alert-in-person-${var.env_name}"
}

resource "newrelic_alert_policy" "enduser" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "alert-enduser-${var.env_name}"
}

# Notification Destinations
resource "newrelic_notification_destination" "opsgenie" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "opsgenie-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = "https://api.opsgenie.com/v2/alerts?apiKey=${data.aws_s3_object.opsgenie_apikey.body}"
  }
}

resource "newrelic_notification_destination" "opsgenie_low" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "opsgenie-low-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = "https://api.opsgenie.com/v2/alerts?apiKey=${data.aws_s3_object.opsgenie_low_apikey.body}"
  }
}

resource "newrelic_notification_destination" "opsgenie_enduser" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "opsgenie-enduser-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = "https://api.opsgenie.com/v2/alerts?apiKey=${data.aws_s3_object.opsgenie_enduser_apikey.body}"
  }
}

resource "newrelic_notification_destination" "slack_low" {
  count = var.enabled
  name  = "slack-low-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = data.aws_s3_object.slack_low_webhook_url.body
  }
}

resource "newrelic_notification_destination" "slack_high" {
  count = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name  = "slack-high-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = data.aws_s3_object.slack_high_webhook_url.body
  }
}

# Notification Channels
resource "newrelic_notification_channel" "opsgenie_low" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "opsgenie-low-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.opsgenie_low[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.opsgenie_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "opsgenie_high" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "opsgenie-high-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.opsgenie[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.opsgenie_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "opsgenie_in_person" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "opsgenie-in-person-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.opsgenie[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.opsgenie_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "opsgenie_enduser" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "opsgenie-enduser-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.opsgenie_enduser[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.opsgenie_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_low" {
  count          = var.enabled
  name           = "slack-low-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_low[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_low_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_high" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "slack-high-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_high[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_high_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_in_person" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "slack-low-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_low[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_high_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_enduser" {
  count          = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name           = "slack-high-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_high[0].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_high_payload_template
    label = "Payload Template"
  }
}


# Workflows 
resource "newrelic_workflow" "low" {
  count                 = var.enabled
  name                  = "low-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.low[0].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_low[0].id
  }
}

resource "newrelic_workflow" "high" {
  count                 = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name                  = "high-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.high[0].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_high[0].id
  }

  destination {
    channel_id = newrelic_notification_channel.opsgenie_high[0].id
  }
}

resource "newrelic_workflow" "in_person" {
  count                 = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name                  = "in_person-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.in_person[0].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_in_person[0].id
  }

  destination {
    channel_id = newrelic_notification_channel.opsgenie_in_person[0].id
  }
}

resource "newrelic_workflow" "enduser" {
  count                 = (var.enabled + var.pager_alerts_enabled) >= 2 ? 1 : 0
  name                  = "enduser-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.enduser[0].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_enduser[0].id
  }

  destination {
    channel_id = newrelic_notification_channel.opsgenie_enduser[0].id
  }
}