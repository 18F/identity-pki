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
  slack_channel_map = {
    "events"      = "login-events"
    "otherevents" = "login-otherevents"
    "soc"         = "login-soc-events"
  }
}

## Terraform providers cannot be generated, so we need a separate block for each region,
## at least for now. TODO: look into using terragrunt / another application to iterate
## through regions, rather than duplicating the code.

## us-west-2

resource "aws_sns_topic" "slack_usw2" {
  for_each = toset(keys(local.slack_channel_map))

  name = "slack-${each.key}"
}

module "slack_lambda_usw2" {
  for_each = local.slack_channel_map
  source = "github.com/18F/identity-terraform//slack_lambda?ref=7de782c072b4a2b869f986d710e5e2bcf6023f0f"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name                 = "snstoslack_login_${each.key}"
  lambda_description          = "Sends messages to #login-${each.key} Slack channel via SNS subscription."
  slack_webhook_url_parameter = aws_ssm_parameter.slack_webhook.name
  slack_channel               = each.value
  slack_username              = var.slack_username
  slack_icon                  = var.slack_icon
  slack_topic_arn             = aws_sns_topic.slack_usw2[each.key].arn
}

module "opsgenie_sns" {
  count = var.opsgenie_key_ready ? 1 : 0
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

module "slack_lambda_use1" {
  for_each = local.slack_channel_map
  source = "github.com/18F/identity-terraform//slack_lambda?ref=7de782c072b4a2b869f986d710e5e2bcf6023f0f"
  #source = "../../../../identity-terraform/slack_lambda"
  providers = {
    aws = aws.use1
  }
  
  lambda_name        = "snstoslack_login_${each.key}"
  lambda_description = "Sends messages to #login-${each.key} Slack channel via SNS subscription."
  slack_webhook_url_parameter  = aws_ssm_parameter.slack_webhook.name
  slack_channel      = each.value
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_use1[each.key].arn
}
