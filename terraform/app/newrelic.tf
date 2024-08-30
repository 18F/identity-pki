data "aws_s3_object" "newrelic_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_apikey"
}

# NOTE: this S3 object needs to be uploaded with --content-type text/plain
# This is the NewRelic account ID
# see https://registry.terraform.io/providers/newrelic/newrelic/latest/docs#argument-reference

data "aws_s3_object" "newrelic_account_id" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_account_id"
}

provider "newrelic" {
  region     = "US"
  account_id = data.aws_s3_object.newrelic_account_id.body
  api_key    = data.aws_s3_object.newrelic_apikey.body
}

data "newrelic_account" "current" {}

module "newrelic" {
  source = "../modules/newrelic/"

  enabled                                    = var.newrelic_alerts_enabled
  staticsite_alerts_enabled                  = var.staticsite_newrelic_alerts_enabled
  idp_enabled                                = var.idp_newrelic_alerts_enabled
  pager_alerts_enabled                       = var.new_relic_pager_alerts_enabled
  in_person_enabled                          = var.idp_in_person_newrelic_alerts_enabled
  doc_auth_enabled                           = var.idp_doc_auth_newrelic_alerts_enabled
  proofing_javascript_error_alerts_enabled   = var.idp_proofing_javascript_error_new_relic_alerts_enabled
  enduser_enabled                            = var.idp_enduser_newrelic_alerts_enabled
  dashboard_enabled                          = var.dashboard_newrelic_alerts_enabled
  cdn_idp_static_assets_alarms_enabled       = var.cdn_idp_static_assets_newrelic_alarms_enabled
  region                                     = var.region
  env_name                                   = var.env_name
  pivcac_low_traffic_alert_threshold         = var.pivcac_low_traffic_alert_threshold
  root_domain                                = var.root_domain
  web_low_traffic_alert_threshold            = var.web_low_traffic_alert_threshold
  web_low_traffic_warn_threshold             = var.web_low_traffic_warn_threshold
  error_dashboard_site                       = "${var.env_name}.${var.root_domain}"
  memory_free_threshold_byte                 = var.memory_free_threshold_byte
  proofing_pageview_duration_alert_threshold = var.proofing_pageview_duration_alert_threshold
  low_memory_alert_enabled                   = var.low_memory_alert_enabled
  waf_alerts_enabled                         = var.waf_alerts_enabled
  incident_manager_teams                     = local.incident_manager_teams
  incident_manager_enabled                   = var.incident_manager_enabled
}


data "aws_iam_policy_document" "new_relic_event_bridge" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "new_relic" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [for val in local.incident_manager_teams : "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function/${val}-incident-manager-actions"]
  }
}

resource "aws_iam_role" "new_relic" {
  name               = "NewRelicEventBus-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.new_relic_event_bridge.json
}

resource "aws_iam_policy" "new_relic" {
  name   = "NewRelicEventBus-${var.env_name}"
  policy = data.aws_iam_policy_document.new_relic.json
}

resource "aws_iam_role_policy_attachment" "new_relic" {
  policy_arn = aws_iam_policy.new_relic.arn
  role       = aws_iam_role.new_relic.name
}


resource "aws_cloudwatch_event_bus" "new_relic" {
  for_each          = toset((var.new_relic_pager_alerts_enabled + var.newrelic_alerts_enabled + var.incident_manager_enabled >= 3) ? local.incident_manager_teams : [])
  name              = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
  event_source_name = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
}

resource "aws_cloudwatch_event_rule" "new_relic" {
  for_each       = toset((var.new_relic_pager_alerts_enabled + var.newrelic_alerts_enabled + var.incident_manager_enabled >= 3) ? local.incident_manager_teams : [])
  name           = "new-relic-incident-manager-${each.value}-${var.env_name}"
  event_bus_name = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
  description    = "Send New Relic alerts to Incident Manager"

  event_pattern = jsonencode({
    "source" : [{
      "prefix" : "aws.partner/newrelic.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "new_relic" {
  for_each       = toset((var.new_relic_pager_alerts_enabled + var.newrelic_alerts_enabled + var.incident_manager_enabled >= 3) ? local.incident_manager_teams : [])
  rule           = aws_cloudwatch_event_rule.new_relic[each.value].name
  event_bus_name = "aws.partner/newrelic.com/${data.newrelic_account.current.account_id}/${each.value}-${var.env_name}"
  target_id      = "new-relic-incident-manager-${each.value}-${var.env_name}"
  arn = join(":", [
    "arn:aws:lambda",
    var.region,
    data.aws_caller_identity.current.account_id,
    "function:${each.value == "appdev_enduser" ? "appdev" : each.value}-incident-manager-actions"
  ])

}