# TODO: decide if we use common/ for each account, or use the
# common_account_name logic as used above for the slack_webhook object
data "aws_s3_bucket_object" "opsgenie_sns_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_sns_apikey"
}

# do not put the actual webhook url value in terraform
resource "aws_ssm_parameter" "slack_webhook" {
  name = "/account/slack/webhook/url"
  type = "SecureString"
  description = "Slack webhook url for notifications"
  value = "Starter"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

locals {
  slack_channel_list = [
    "login-events",
    "login-otherevents",
    "login-soc-events",
  ]
}

## Terraform providers cannot be generated, so we need a separate block for each region,
## at least for now. TODO: look into using terragrunt / another application to iterate
## through regions, rather than duplicating the code.

## us-west-2

resource "aws_sns_topic" "slack_usw2" {
  for_each = toset(local.slack_channel_list)

  name = "sns-slack-${each.key}"
}

module "slack_lambda_usw2" {
  for_each = toset(local.slack_channel_list)
  source = "github.com/18F/identity-terraform//slack_lambda?ref=7de782c072b4a2b869f986d710e5e2bcf6023f0f"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "SNSToSlack-${each.key}"
  lambda_description = "Sends messages to #${each.key} Slack channel via SNS subscription."
  slack_webhook_url_parameter  = aws_ssm_parameter.slack_webhook.name
  slack_channel      = each.key
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_usw2[each.key].arn
}

resource "aws_sns_topic" "opsgenie_alert_usw2" {
  name = "opsgenie-alert"
}

resource "aws_sns_topic_subscription" "opsgenie_alert_usw2" {
  topic_arn = aws_sns_topic.opsgenie_alert_usw2.arn
  endpoint_auto_confirms = true
  protocol  = "https"
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}

## us-east-1

resource "aws_sns_topic" "slack_use1" {
  for_each = toset(local.slack_channel_list)

  name = "sns-slack-${each.key}"
}

module "slack_lambda_use1" {
  for_each = toset(local.slack_channel_list)
  source = "github.com/18F/identity-terraform//slack_lambda?ref=7de782c072b4a2b869f986d710e5e2bcf6023f0f"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "SNSToSlack-${each.key}"
  lambda_description = "Sends messages to #${each.key} Slack channel via SNS subscription."
  slack_webhook_url_parameter  = aws_ssm_parameter.slack_webhook.name
  slack_channel      = each.key
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_use1[each.key].arn
}

resource "aws_sns_topic" "opsgenie_alert_use1" {
  name = "opsgenie-alert"
}

resource "aws_sns_topic_subscription" "opsgenie_alert_use1" {
  topic_arn = aws_sns_topic.opsgenie_alert_use1.arn
  endpoint_auto_confirms = true
  protocol  = "https"
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}
