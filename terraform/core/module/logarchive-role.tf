# All roles are currently conditional based on whether or not:
# 1. var.logarchive_acct_id has been specified
# 2. var.logarchive_secondary_region is true/false

module "logarchive_role_kinesis_primary" {
  count  = length(var.logarchive_acct_id) != 0 ? 1 : 0
  source = "../../modules/logarchive_cross_account_role"
  providers = {
    aws = aws.usw2
  }

  logarchive_acct_id = var.logarchive_acct_id
  logarchive_destination_name = join("-", [
    "logarchive",
    local.aws_alias,
    "kinesis",
    data.aws_region.current.name
  ])
}

module "logarchive_role_kinesis_secondary" {
  count  = length(var.logarchive_acct_id) != 0 && length(var.logarchive_secondary_region) != 0 ? 1 : 0
  source = "../../modules/logarchive_cross_account_role"
  providers = {
    aws = aws.use1
  }

  logarchive_acct_id = var.logarchive_acct_id
  logarchive_destination_name = join("-", [
    "logarchive",
    local.aws_alias,
    "kinesis",
    var.logarchive_secondary_region
  ])
}
