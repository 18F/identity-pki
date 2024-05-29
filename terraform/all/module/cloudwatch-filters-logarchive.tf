# NOTE: Until we've finalized the naming schema for other types of Log Groups,
# certain groups we'll send to the logarchive account(s) are noted here,
# but commented out, so as not to create random S3 paths with their current names.
# They can be uncommented once we've settled on a proper organizational structure
# AND have updated the underlying applications to use the new Log Group names/paths
# in CloudWatch, as these refer to the Terraform resources and are not hard-coded.

##### us-west-2 #####

module "logarchive_uw2" {
  count  = length(var.logarchive_acct_id) != 0 ? 1 : 0
  source = "../../modules/logarchive_subscription_filter"
  providers = {
    aws = aws.usw2
  }

  logarchive_acct_id = var.logarchive_acct_id
  log_groups = {
    #"cloudwatch" = flatten([
    #  [for group in aws_cloudwatch_log_group.account_uw2 : group.name if(
    #  group.name != "RDSOSMetrics")], # cloudwatch-log-groups.tf
    #]),
    #"rds" = flatten([
    #  aws_cloudwatch_log_group.account_uw2["RDSOSMetrics"].name, # cloudwatch-log-groups.tf
    #])
  }
}

##### us-east-1 #####

module "logarchive_ue1" {
  count  = length(var.logarchive_acct_id) != 0 && var.logarchive_use1_enabled ? 1 : 0
  source = "../../modules/logarchive_subscription_filter"
  providers = {
    aws = aws.use1
  }

  logarchive_acct_id = var.logarchive_acct_id
  log_groups = {
    #"cloudwatch" = flatten([
    #  [for group in aws_cloudwatch_log_group.account_ue1 : group.name if(
    #  group.name != "RDSOSMetrics")], # cloudwatch-log-groups.tf
    #]),
    #"rds" = flatten([
    #  aws_cloudwatch_log_group.account_ue1["RDSOSMetrics"].name, # cloudwatch-log-groups.tf
    #])
  }
}
