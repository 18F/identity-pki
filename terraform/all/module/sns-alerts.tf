# do not put the actual webhook url value in terraform
resource "aws_ssm_parameter" "slack_webhook" {
  name        = "/account/slack/webhook/url"
  type        = "SecureString"
  description = "Slack webhook url for notifications"
  value       = "Starter"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "slack_webhook_east1" {
  provider    = aws.use1
  name        = local.slack_webhook_ssm_param_name
  type        = "SecureString"
  description = "Slack webhook url for notifications"
  value       = "Starter"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

locals {
  slack_channel_map = {
    "events"      = "login-events"
    "otherevents" = "login-otherevents"
    "soc"         = "login-soc-events"
  }
  slack_webhook_ssm_param_name = "/account/slack/webhook/url"
}

## Terraform providers cannot be generated, so we need a separate block for each region,
## at least for now. TODO: look into using terragrunt / another application to iterate
## through regions, rather than duplicating the code.

## us-west-2

resource "aws_sns_topic" "slack_usw2" {
  for_each = toset(keys(local.slack_channel_map))

  name = "slack-${each.key}"
}

resource "aws_sns_topic_policy" "slack_usw2" {
  for_each = local.slack_channel_map
  arn      = aws_sns_topic.slack_usw2[each.key].arn
  policy   = data.aws_iam_policy_document.sns_topic_policy_usw2[each.key].json
}

data "aws_iam_policy_document" "sns_topic_policy_usw2" {
  for_each = local.slack_channel_map
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-${each.key}"]
  }
}

resource "aws_ssm_parameter" "account_alarm_slack_usw2" {
  for_each = local.slack_channel_map

  name        = "/account/us-west-2/alert/sns/arn_slack_${each.key}"
  type        = "String"
  value       = aws_sns_topic.slack_usw2[each.key].arn
  description = "Alarm notification topic for #${each.value}"
  overwrite   = true
}

module "slack_lambda_usw2" {
  for_each = local.slack_channel_map
  source   = "github.com/18F/identity-terraform//slack_lambda?ref=06d80f2308c4832e8139dc8e36690f79fea5cf22"
  #source = "../../../../identity-terraform/slack_lambda"

  lambda_name                 = "snstoslack_login_${each.key}"
  lambda_description          = "Sends messages to #login-${each.key} Slack channel via SNS subscription. "
  slack_webhook_url_parameter = local.slack_webhook_ssm_param_name
  slack_channel               = each.value
  slack_username              = var.slack_username
  slack_icon                  = var.slack_icon
  slack_topic_arn             = aws_sns_topic.slack_usw2[each.key].arn
}

module "opsgenie_sns" {
  count  = var.opsgenie_key_ready ? 1 : 0
  source = "../../modules/opsgenie_sns"
  providers = {
    aws.usw2 = aws.usw2
    aws.use1 = aws.use1
  }
}

## us-east-1

resource "aws_sns_topic" "slack_use1" {
  provider = aws.use1
  for_each = local.slack_channel_map

  name = "slack-${each.key}"
}

resource "aws_sns_topic_policy" "slack_use1" {
  provider = aws.use1
  for_each = local.slack_channel_map
  arn      = aws_sns_topic.slack_use1[each.key].arn
  policy   = data.aws_iam_policy_document.sns_topic_policy_use1[each.key].json
}

data "aws_iam_policy_document" "sns_topic_policy_use1" {
  for_each = local.slack_channel_map
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["arn:aws:sns:us-east-1:${data.aws_caller_identity.current.account_id}:slack-${each.key}"]
  }
}

resource "aws_ssm_parameter" "account_alarm_slack_use1" {
  for_each = local.slack_channel_map

  name        = "/account/us-east-1/alert/sns/arn_slack_${each.key}"
  type        = "String"
  value       = aws_sns_topic.slack_use1[each.key].arn
  description = "Alarm notification topic for #${each.value}"
  overwrite   = true
}

module "slack_lambda_use1" {
  for_each = local.slack_channel_map
  source   = "github.com/18F/identity-terraform//slack_lambda?ref=06d80f2308c4832e8139dc8e36690f79fea5cf22"
  #source = "../../../../identity-terraform/slack_lambda"
  providers = {
    aws = aws.use1
  }

  lambda_name                 = "snstoslack_login_${each.key}"
  lambda_description          = "Sends messages to #login-${each.key} Slack channel via SNS subscription."
  slack_webhook_url_parameter = local.slack_webhook_ssm_param_name
  slack_channel               = each.value
  slack_username              = var.slack_username
  slack_icon                  = var.slack_icon
  slack_topic_arn             = aws_sns_topic.slack_use1[each.key].arn
}
