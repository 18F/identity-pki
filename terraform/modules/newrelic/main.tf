# this file sets up newrelic alerts for metrics
# Once we get tf 0.13.* going, we can get rid of all the count and [0] silliness

locals {
  slack_payload_template = <<-EOF
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

  incident_manager_payload_template = <<-EOF
{
  "alarmName": {{ json annotations.title.[0] }},
  "state":{
    "reason": {{ json annotations.title.[0] }},
    "reasonData": {
      "IssueID": {{json issueId}},
      "IssueURL": {{json issuePageUrl}},
      "NewRelic priority": {{json priority}},
      "Runbook": "{{#each accumulations.runbookUrl}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
      "Description": "{{#each annotations.description}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
      "Alert Policy Names": "{{#each accumulations.policyName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
      "Alert Condition Names": "{{#each accumulations.conditionName}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}",
      "Workflow Name": {{json workflowName}}
      },
    "timestamp": {{ createdAt }},
    "value":"ALARM"
  },
  "configuration":{
    "description":"Test"
  }
}
EOF

}

data "aws_caller_identity" "current" {}
data "newrelic_account" "current" {}

# These Slack URLs need to be uploaded to S3 with --content-type text/plain
data "aws_s3_object" "slack_low_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/otherevents_webhook_url"
}

data "aws_s3_object" "slack_high_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/alarms_webhook_url"
}

data "aws_s3_object" "slack_in_person_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/in_person_webhook_url"
}

data "aws_s3_object" "slack_doc_auth_webhook_url" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/slack/doc_auth_webhook_url"
}

# Logic for notification channels/destinations is as follows:
#
# 1. All alert policies are created, regardless of var.pager_alerts_enabled
# 2. Slack notification channels/destinations are always created
# 3. If var.pager_alerts_enabled = true, high / enduser should all
#    go to the 'high' slack destination; otherwise, they should all go to the 'low' one
# 4. If var.pager_alerts_enabled = true, then on-call paging channels/destinations
#    are also created
#

# Alert Policies
resource "newrelic_alert_policy" "low" {
  count = var.enabled
  name  = "alert-low-${var.env_name}"
}

resource "newrelic_alert_policy" "high" {
  count = var.enabled
  name  = "alert-high-${var.env_name}"
}

resource "newrelic_alert_policy" "in_person" {
  count = (var.enabled + var.in_person_enabled) >= 2 ? 1 : 0
  name  = "alert-in-person-${var.env_name}"
}

resource "newrelic_alert_policy" "doc_auth" {
  count = (var.enabled + var.doc_auth_enabled) >= 2 ? 1 : 0
  name  = "alert-doc-auth-${var.env_name}"
}

resource "newrelic_alert_policy" "enduser" {
  count = (var.enabled + var.enduser_enabled) >= 2 ? 1 : 0
  name  = "alert-enduser-${var.env_name}"
}

# Notification Destinations
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

resource "newrelic_notification_destination" "slack_in_person" {
  count = (var.enabled + var.in_person_enabled) >= 2 ? 1 : 0
  name  = "slack-in-person-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = data.aws_s3_object.slack_in_person_webhook_url.body
  }
}

resource "newrelic_notification_destination" "slack_doc_auth" {
  count = (var.enabled + var.doc_auth_enabled) >= 2 ? 1 : 0
  name  = "slack-doc-auth-${var.env_name}"
  type  = "WEBHOOK"

  property {
    key   = "url"
    value = data.aws_s3_object.slack_doc_auth_webhook_url.body
  }
}

resource "newrelic_notification_destination" "incident_manager" {
  for_each = toset((var.enabled + var.pager_alerts_enabled + var.incident_manager_enabled >= 3) ? var.incident_manager_teams : [])
  name     = "incident-manager-oncall-${each.value}-${var.env_name}"
  type     = "EVENT_BRIDGE"

  property {
    key   = "AWSAccountId"
    value = data.aws_caller_identity.current.account_id
  }

  property {
    key   = "AWSRegion"
    value = "us-west-2"
  }
}

# Notification Channels
resource "newrelic_notification_channel" "slack_low" {
  count          = var.enabled
  name           = "slack-low-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_low[count.index].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_high" {
  count = var.enabled
  name  = "slack-high-${var.env_name}"
  type  = "WEBHOOK"
  destination_id = var.pager_alerts_enabled == 1 ? (
    newrelic_notification_destination.slack_high[count.index].id) : (
  newrelic_notification_destination.slack_low[count.index].id)
  product = "IINT"

  property {
    key   = "payload"
    value = local.slack_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_in_person" {
  count          = (var.enabled + var.in_person_enabled) >= 2 ? 1 : 0
  name           = "slack-in-person-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_in_person[count.index].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_doc_auth" {
  count          = (var.enabled + var.doc_auth_enabled) >= 2 ? 1 : 0
  name           = "slack-slack-doc-auth-${var.env_name}"
  type           = "WEBHOOK"
  destination_id = newrelic_notification_destination.slack_doc_auth[count.index].id
  product        = "IINT"

  property {
    key   = "payload"
    value = local.slack_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "slack_enduser" {
  count = (var.enabled + var.enduser_enabled) >= 2 ? 1 : 0
  name  = "slack-high-${var.env_name}"
  type  = "WEBHOOK"
  destination_id = var.pager_alerts_enabled == 1 ? (
    newrelic_notification_destination.slack_high[count.index].id) : (
  newrelic_notification_destination.slack_low[count.index].id)
  product = "IINT"

  property {
    key   = "payload"
    value = local.slack_payload_template
    label = "Payload Template"
  }
}

resource "newrelic_notification_channel" "incident_manager" {
  for_each       = toset((var.enabled + var.pager_alerts_enabled + var.incident_manager_enabled >= 3) ? var.incident_manager_teams : [])
  name           = "incident-manager-oncall-${each.key}-${var.env_name}"
  type           = "EVENT_BRIDGE"
  destination_id = newrelic_notification_destination.incident_manager[each.value].id
  product        = "IINT"

  property {
    key   = "eventSource"
    value = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
  }

  property {
    key   = "eventContent"
    value = local.incident_manager_payload_template
  }

}

resource "newrelic_notification_channel" "incident_manager_enduser" {
  for_each       = toset((var.enabled + var.pager_alerts_enabled + var.incident_manager_enabled >= 3) ? ["appdev_enduser"] : [])
  name           = "incident-manager-oncall-appdev-${var.env_name}"
  type           = "EVENT_BRIDGE"
  destination_id = newrelic_notification_destination.incident_manager["appdev"].id
  product        = "IINT"

  property {
    key   = "eventSource"
    value = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
  }

  property {
    key   = "eventContent"
    value = local.incident_manager_payload_template
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
      values    = [newrelic_alert_policy.low[count.index].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_low[count.index].id
  }
}

resource "newrelic_workflow" "high" {
  count                 = var.enabled
  name                  = "high-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.high[count.index].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_high[count.index].id
  }

  dynamic "destination" {
    # Targets all incident manager teams
    for_each = toset((var.enabled + var.pager_alerts_enabled + var.incident_manager_enabled >= 3) ? var.incident_manager_teams : [])

    content {
      channel_id = newrelic_notification_channel.incident_manager[destination.value].id
    }
  }
}

resource "newrelic_workflow" "in_person" {
  count                 = (var.enabled + var.in_person_enabled) >= 2 ? 1 : 0
  name                  = "in-person-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.in_person[count.index].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_in_person[count.index].id
  }
}

resource "newrelic_workflow" "doc_auth" {
  count                 = (var.enabled + var.doc_auth_enabled) >= 2 ? 1 : 0
  name                  = "doc-auth-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.doc_auth[count.index].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_doc_auth[count.index].id
  }
}

resource "newrelic_workflow" "enduser" {
  count                 = (var.enabled + var.enduser_enabled) >= 2 ? 1 : 0
  name                  = "enduser-${var.env_name}"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.enduser[count.index].id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.slack_enduser[count.index].id
  }

  dynamic "destination" {
    for_each = toset((var.enabled + var.pager_alerts_enabled + var.incident_manager_enabled) >= 3 ? ["appdev_enduser"] : [])

    content {
      channel_id = newrelic_notification_channel.incident_manager_enduser[destination.value].id
    }
  }

}
