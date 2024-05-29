##### Variables

variable "log_groups" {
  type        = map(list(string))
  description = <<EOM
CloudWatch Log groups to create Subscription Filters for.
Should be of the format { source_service = [ log_group1, log_group2, ] }
for each source_service to use as a directory name in S3.
All Log Groups in this list will be sent to the same filter of the name format
<source_acct_id>-<region_name>-<source_service> to be processed by Kinesis/Lambda
in the appropriate logarchive account.
EOM
}

variable "logarchive_acct_id" {
  type        = string
  description = <<EOM
ID of the 'logarchive' AWS account containing CloudWatch Log Destinations and
Kinesis Data Streams, which the CloudWatch Subscription Filters
created via the this module(s) will send to.
EOM
  default     = ""
}

locals {
  aws_alias = trimprefix(
    data.aws_iam_account_alias.current.account_alias, "login-"
  )
  logarchive_kinesis_role_and_dest = join("-", [
    "logarchive-${local.aws_alias}",
    "kinesis-${data.aws_region.current.name}"
  ])
}

##### Data Sources

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_account_alias" "current" {}

data "aws_iam_role" "logarchive_cross_account" {
  name = local.logarchive_kinesis_role_and_dest
}

##### Resources

resource "aws_cloudwatch_log_subscription_filter" "logarchive" {
  for_each = { for k, v in transpose(var.log_groups) : k => v[0] }
  name = join("-", [
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.name,
    each.value
  ])
  log_group_name = each.key
  filter_pattern = ""
  destination_arn = join(":", [
    "arn:aws:logs:${data.aws_region.current.name}:${var.logarchive_acct_id}",
    "destination:${local.logarchive_kinesis_role_and_dest}"
  ])
  distribution = "ByLogStream"
  role_arn     = data.aws_iam_role.logarchive_cross_account.arn
}
