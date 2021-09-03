terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [
        aws.usw2,
        aws.use1
      ]
    }
  }
  required_version = ">= 0.13.7"
}

variable "region" {
  description = "Region the secrets bucket has been created in"
  default     = "us-west-2"
}

data "aws_caller_identity" "current" {
}

data "aws_s3_bucket_object" "opsgenie_sns_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_sns_apikey"
}

## Terraform providers cannot be generated, so we need a separate block for each region,
## at least for now. TODO: look into using terragrunt / another application to iterate
## through regions, rather than duplicating the code.

## us-west-2

resource "aws_sns_topic" "opsgenie_alert_usw2" {
  provider = aws.usw2
  name     = "opsgenie-alert"
}

resource "aws_sns_topic_policy" "opsgenie_usw2" {
  provider = aws.usw2
  arn      = aws_sns_topic.opsgenie_alert_usw2.arn
  policy   = data.aws_iam_policy_document.opsgenie_sns_topic_policy_usw2.json
}

data "aws_iam_policy_document" "opsgenie_sns_topic_policy_usw2" {
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.opsgenie_alert_usw2.arn]
  }
}

resource "aws_sns_topic_subscription" "opsgenie_alert_usw2" {
  provider               = aws.usw2
  topic_arn              = aws_sns_topic.opsgenie_alert_usw2.arn
  endpoint_auto_confirms = true
  protocol               = "https"
  endpoint               = "https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}

resource "aws_sns_topic" "opsgenie_alert_use1" {
  provider = aws.use1
  name     = "opsgenie-alert"
}

resource "aws_sns_topic_policy" "opsgenie_use1" {
  provider = aws.use1
  arn      = aws_sns_topic.opsgenie_alert_use1.arn
  policy   = data.aws_iam_policy_document.opsgenie_sns_topic_policy_use1.json
}

data "aws_iam_policy_document" "opsgenie_sns_topic_policy_use1" {
  statement {
    sid     = "Allow_Publish_Events"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.opsgenie_alert_use1.arn]
  }
}

resource "aws_sns_topic_subscription" "opsgenie_alert_use1" {
  provider               = aws.use1
  topic_arn              = aws_sns_topic.opsgenie_alert_use1.arn
  endpoint_auto_confirms = true
  protocol               = "https"
  endpoint               = "https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}

output "usw2_sns_topic_arn" {
  description = "ARN of the SNS topic in US-WEST-2."
  value       = aws_sns_topic.opsgenie_alert_usw2.arn
}

output "use1_sns_topic_arn" {
  description = "ARN of the SNS topic in US-EAST-1."
  value       = aws_sns_topic.opsgenie_alert_use1.arn
}