locals {
  cloudwatch_log_group_names = [
    "/aws-glue/crawlers",
    "/aws-glue/jobs/error",
    "/aws-glue/jobs/output",
    "/aws/ssm/AWS-RunShellScript",
    "/var/log/cloud-init-output.log",
    "/var/log/cloud-init.log",
    "RDSOSMetrics",
  ]
}

resource "aws_cloudwatch_log_group" "account_uw2" {
  for_each = toset(sort(flatten([
    local.cloudwatch_log_group_names,
    var.account_cloudwatch_log_groups
  ])))
  provider = aws.usw2

  name              = each.key
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = true
}

moved {
  from = aws_cloudwatch_log_group.account
  to   = aws_cloudwatch_log_group.account_uw2
}

resource "aws_cloudwatch_log_group" "account_ue1" {
  for_each = var.logarchive_use1_enabled ? toset(sort(flatten([
    local.cloudwatch_log_group_names,
    var.account_cloudwatch_log_groups
  ]))) : []
  provider = aws.use1

  name              = each.key
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = true
}
