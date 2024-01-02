variable "logarchive_acct_id" {
  type        = string
  description = <<EOM
ID of the 'logarchive' AWS account containing CloudWatch Log Destinations and
Kinesis Data/Firehose Streams, which CloudWatch Subscription Filters will send to.
EOM
}

variable "logarchive_destination_name" {
  type        = string
  description = <<EOM
Name of the CloudWatch Log Destination that the Subscription Filters will send to.
EOM
}

##### Data Sources

data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

##### Resources

data "aws_iam_policy_document" "cloudwatch_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_destination_access" {
  statement {
    sid    = "AllowCreatingSubscriptionFiltersToDestinations"
    effect = "Allow"
    actions = [
      "logs:PutSubscriptionFilter"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:*",
      "arn:aws:logs:*:${var.logarchive_acct_id}:destination:${var.logarchive_destination_name}"
    ]
  }
}

resource "aws_iam_role" "cloudwatch_logarchive" {
  name               = var.logarchive_destination_name
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role.json
}

resource "aws_iam_role_policy" "cloudwatch_logarchive" {
  name   = var.logarchive_destination_name
  role   = aws_iam_role.cloudwatch_logarchive.name
  policy = data.aws_iam_policy_document.cloudwatch_destination_access.json
}
