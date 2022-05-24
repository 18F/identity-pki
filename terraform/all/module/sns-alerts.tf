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
  slack_sns_log_groups_arns = flatten([
    [for group in aws_cloudwatch_log_group.slack_usw2_success_logs_groups : "${group.arn}:*"],
    [for group in aws_cloudwatch_log_group.slack_usw2_failure_logs_groups : "${group.arn}:*"],
    [for group in aws_cloudwatch_log_group.slack_use1_success_logs_groups : "${group.arn}:*"],
    [for group in aws_cloudwatch_log_group.slack_use1_failure_logs_groups : "${group.arn}:*"],
  ])
}

## SNS Feedback

data "aws_iam_policy_document" "sns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "slack_SNSFeedback_policy_document" {
  statement {
    sid    = "AllowFeedback"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      for arn in local.slack_sns_log_groups_arns : "${arn}"
    ]
  }
}
resource "aws_iam_policy" "slack_SNS_Feedback_policy" {
  name   = "slackSNSFeedbackPolicy"
  policy = data.aws_iam_policy_document.slack_SNSFeedback_policy_document.json
}

resource "aws_iam_role" "slack_SNSFailureFeedback" {
  name                = "slack_SNSFailureFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.slack_SNS_Feedback_policy.arn]
}

resource "aws_iam_role" "slack_SNSSuccessFeedback" {
  name                = "slack_SNSSuccessFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.slack_SNS_Feedback_policy.arn]
}

## Terraform providers cannot be generated, so we need a separate block for each region,
## at least for now. TODO: look into using terragrunt / another application to iterate
## through regions, rather than duplicating the code.

## us-west-2 

resource "aws_cloudwatch_log_group" "slack_usw2_success_logs_groups" {
  for_each = toset(keys(local.slack_channel_map))

  name              = "sns/us-west-2/${data.aws_caller_identity.current.account_id}/slack-${each.key}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "slack_usw2_failure_logs_groups" {
  for_each = toset(keys(local.slack_channel_map))

  name              = "sns/us-west-2/${data.aws_caller_identity.current.account_id}/slack-${each.key}/Failure"
  retention_in_days = 365
}

resource "aws_sns_topic" "slack_usw2" {
  for_each = toset(keys(local.slack_channel_map))

  name                                = "slack-${each.key}"
  lambda_success_feedback_role_arn    = aws_iam_role.slack_SNSSuccessFeedback.arn
  lambda_failure_feedback_role_arn    = aws_iam_role.slack_SNSFailureFeedback.arn
  lambda_success_feedback_sample_rate = 100
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
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "cloudwatch.amazonaws.com",
        "codestar-notifications.amazonaws.com"
      ]
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
  source   = "github.com/18F/identity-terraform//slack_lambda?ref=0fe0243d7df353014c757a72ef0c48f5805fb3d3"
  #source = "../../../../identity-terraform/slack_lambda"

  lambda_name                 = "snstoslack_login_${each.key}"
  lambda_description          = "Sends messages to #login-${each.key} Slack channel via SNS subscription."
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

resource "aws_cloudwatch_log_group" "slack_use1_success_logs_groups" {
  provider = aws.use1
  for_each = toset(keys(local.slack_channel_map))

  name              = "sns/us-east-1/${data.aws_caller_identity.current.account_id}/slack-${each.key}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "slack_use1_failure_logs_groups" {
  provider = aws.use1
  for_each = toset(keys(local.slack_channel_map))

  name              = "sns/us-east-1/${data.aws_caller_identity.current.account_id}/slack-${each.key}/Failure"
  retention_in_days = 365
}

resource "aws_sns_topic" "slack_use1" {
  provider = aws.use1
  for_each = local.slack_channel_map

  name                                = "slack-${each.key}"
  lambda_success_feedback_role_arn    = aws_iam_role.slack_SNSSuccessFeedback.arn
  lambda_failure_feedback_role_arn    = aws_iam_role.slack_SNSFailureFeedback.arn
  lambda_success_feedback_sample_rate = 100
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
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "cloudwatch.amazonaws.com"
      ]
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
  source   = "github.com/18F/identity-terraform//slack_lambda?ref=0fe0243d7df353014c757a72ef0c48f5805fb3d3"
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
