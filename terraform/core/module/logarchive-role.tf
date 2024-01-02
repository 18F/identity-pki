# All roles are currently conditional based on whether or not:
# 1. var.logarchive_acct_id has been specified
# 2. var.logarchive_secondary_region is true/false
#
# Currently this will create roles/policies for both of our different
# CloudWatch Destination module types (Kinesis Data Stream and Data Firehose)
# until one solution is decided on over the other.
# TODO: determine this with load testing and other prep.

### DATA STREAM

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

### FIREHOSE

module "logarchive_role_firehose_primary" {
  count  = length(var.logarchive_acct_id) != 0 ? 1 : 0
  source = "../../modules/logarchive_cross_account_role"
  providers = {
    aws = aws.usw2
  }

  logarchive_acct_id = var.logarchive_acct_id
  logarchive_destination_name = join("-", [
    "logarchive",
    local.aws_alias,
    "firehose",
    data.aws_region.current.name
  ])
}

module "logarchive_role_firehose_secondary" {
  count  = length(var.logarchive_acct_id) != 0 && length(var.logarchive_secondary_region) != 0 ? 1 : 0
  source = "../../modules/logarchive_cross_account_role"
  providers = {
    aws = aws.use1
  }

  logarchive_acct_id = var.logarchive_acct_id
  logarchive_destination_name = join("-", [
    "logarchive",
    local.aws_alias,
    "firehose",
    var.logarchive_secondary_region
  ])
}
