terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ssm_parameter" "splunk_oncall_endpoint" {
  name        = "/account/splunk_oncall/endpoint"
  type        = "SecureString"
  description = "Base URL for Splunk On-Call alerting"
  value       = var.splunk_oncall_endpoint
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_iam_policy_document" "sns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "splunk_oncall_SNSFeedback_policy_document" {
  statement {
    sid    = "AllowFeedback"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = flatten([
      for k in keys(var.splunk_oncall_routing_keys) : [
        "${aws_cloudwatch_log_group.splunk_oncall_success_sns_log[k].arn}:*",
        "${aws_cloudwatch_log_group.splunk_oncall_failure_sns_log[k].arn}:*",
      ]
    ])
  }
}

resource "aws_iam_policy" "splunk_oncall_SNSFeedback_policy" {
  name   = "splunk_oncallSNSFeedbackPolicy-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.splunk_oncall_SNSFeedback_policy_document.json
}

resource "aws_iam_role" "splunk_oncall_SNSSuccessFeedback" {
  name                = "splunk_oncall_SNSSuccessFeedback-${data.aws_region.current.name}"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.splunk_oncall_SNSFeedback_policy.arn]
}

resource "aws_iam_role" "splunk_oncall_SNSFailureFeedback" {
  name                = "splunk_oncall_SNSFailureFeedback-${data.aws_region.current.name}"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.splunk_oncall_SNSFeedback_policy.arn]
}

resource "aws_cloudwatch_log_group" "splunk_oncall_success_sns_log" {
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "splunk_oncall_failure_sns_log" {
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}/Failure"
  retention_in_days = 365
}

resource "aws_sns_topic" "splunk_oncall_alert" {
  for_each                          = var.splunk_oncall_routing_keys
  name                              = "splunk-oncall-${each.key}"
  display_name                      = each.value
  http_success_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSSuccessFeedback.arn
  http_failure_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSFailureFeedback.arn
  http_success_feedback_sample_rate = 100
}

data "aws_iam_policy_document" "splunk_oncall_sns_topic_policy" {
  for_each = var.splunk_oncall_routing_keys
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "events.amazonaws.com"
      ]
    }

    resources = [aws_sns_topic.splunk_oncall_alert[each.key].arn]
  }
}

resource "aws_sns_topic_policy" "splunk_oncall_policy" {
  for_each = var.splunk_oncall_routing_keys
  arn      = aws_sns_topic.splunk_oncall_alert[each.key].arn
  policy   = data.aws_iam_policy_document.splunk_oncall_sns_topic_policy[each.key].json
}

resource "aws_sns_topic_subscription" "splunk_oncall_alert" {
  # Only create subscriptions if the endpoint is set in the SSM Parameter
  for_each               = aws_ssm_parameter.splunk_oncall_endpoint.value == "UNSET" ? {} : var.splunk_oncall_routing_keys
  topic_arn              = aws_sns_topic.splunk_oncall_alert[each.key].arn
  endpoint_auto_confirms = true
  protocol               = "https"
  endpoint               = "${aws_ssm_parameter.splunk_oncall_endpoint.value}/${each.key}"
}
