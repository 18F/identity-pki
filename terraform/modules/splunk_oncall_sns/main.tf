terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.usw2,
        aws.use1
      ]
    }
  }
}

data "aws_caller_identity" "current" {
}


resource "aws_ssm_parameter" "splunk_oncall_endpoint_usw2" {
  provider    = aws.usw2
  name        = "/account/splunk_oncall/endpoint"
  type        = "SecureString"
  description = "Base URL for Splunk OnCall alerting"
  value       = "Starter"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "splunk_oncall_endpoint_use1" {
  provider    = aws.use1
  name        = "/account/splunk_oncall/endpoint"
  type        = "SecureString"
  description = "Base URL for Splunk OnCall alerting"
  value       = "Starter"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_iam_role" "splunk_oncall_SNSFailureFeedback" {
  name                = "splunk_oncall_SNSFailureFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.splunk_oncall_SNSFeedback_policy.arn]
}

resource "aws_iam_role" "splunk_oncall_SNSSuccessFeedback" {
  name                = "splunk_oncall_SNSSuccessFeedback"
  assume_role_policy  = data.aws_iam_policy_document.sns_assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.splunk_oncall_SNSFeedback_policy.arn]
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

resource "aws_iam_policy" "splunk_oncall_SNSFeedback_policy" {
  name   = "splunk_oncallSNSFeedbackPolicy"
  policy = data.aws_iam_policy_document.splunk_oncall_SNSFeedback_policy_document.json
}

resource "aws_cloudwatch_log_group" "splunk_oncall_success_sns_log_usw2" {
  provider          = aws.usw2
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/us-west-2/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "splunk_oncall_failure_sns_log_usw2" {
  provider          = aws.usw2
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/us-west-2/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}/Failure"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "splunk_oncall_success_sns_log_use1" {
  provider          = aws.use1
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/us-east-1/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "splunk_oncall_failure_sns_log_use1" {
  provider          = aws.use1
  for_each          = var.splunk_oncall_routing_keys
  name              = "sns/us-east-1/${data.aws_caller_identity.current.account_id}/splunk_oncall-${each.key}/Failure"
  retention_in_days = 365
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
        "${aws_cloudwatch_log_group.splunk_oncall_success_sns_log_usw2[k].arn}:*",
        "${aws_cloudwatch_log_group.splunk_oncall_failure_sns_log_usw2[k].arn}:*",
        "${aws_cloudwatch_log_group.splunk_oncall_success_sns_log_use1[k].arn}:*",
        "${aws_cloudwatch_log_group.splunk_oncall_failure_sns_log_use1[k].arn}:*",
      ]
    ])
  }
}

resource "aws_sns_topic" "splunk_oncall_alert_usw2" {
  provider                          = aws.usw2
  for_each                          = var.splunk_oncall_routing_keys
  name                              = "splunk-oncall-${each.key}"
  display_name                      = each.value
  http_success_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSSuccessFeedback.arn
  http_failure_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSFailureFeedback.arn
  http_success_feedback_sample_rate = 100
}

resource "aws_sns_topic" "splunk_oncall_alert_use1" {
  provider                          = aws.use1
  for_each                          = var.splunk_oncall_routing_keys
  name                              = "splunk-oncall-${each.key}"
  display_name                      = each.value
  http_success_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSSuccessFeedback.arn
  http_failure_feedback_role_arn    = aws_iam_role.splunk_oncall_SNSFailureFeedback.arn
  http_success_feedback_sample_rate = 100
}

data "aws_iam_policy_document" "splunk_oncall_sns_topic_policy" {
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = flatten([
      for k in keys(var.splunk_oncall_routing_keys) : [
        aws_sns_topic.splunk_oncall_alert_usw2[k].arn,
        aws_sns_topic.splunk_oncall_alert_use1[k].arn,
      ]
    ])
  }
}

resource "aws_sns_topic_policy" "splunk_oncall_policy_usw2" {
  provider = aws.usw2
  for_each = var.splunk_oncall_routing_keys
  arn      = aws_sns_topic.splunk_oncall_alert_usw2[each.key].arn
  policy   = data.aws_iam_policy_document.splunk_oncall_sns_topic_policy.json
}

resource "aws_sns_topic_policy" "splunk_oncall_policy_use1" {
  provider = aws.use1
  for_each = var.splunk_oncall_routing_keys
  arn      = aws_sns_topic.splunk_oncall_alert_use1[each.key].arn
  policy   = data.aws_iam_policy_document.splunk_oncall_sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "splunk_oncall_alert_usw2" {
  provider               = aws.usw2
  for_each               = var.splunk_oncall_routing_keys
  topic_arn              = aws_sns_topic.splunk_oncall_alert_usw2[each.key].arn
  endpoint_auto_confirms = true
  protocol               = "https"
  endpoint               = "${aws_ssm_parameter.splunk_oncall_endpoint_usw2.value}/${each.key}"
}

resource "aws_sns_topic_subscription" "splunk_oncall_alert_use1" {
  provider               = aws.use1
  for_each               = var.splunk_oncall_routing_keys
  topic_arn              = aws_sns_topic.splunk_oncall_alert_use1[each.key].arn
  endpoint_auto_confirms = true
  protocol               = "https"
  endpoint               = "${aws_ssm_parameter.splunk_oncall_endpoint_use1.value}/${each.key}"
}

