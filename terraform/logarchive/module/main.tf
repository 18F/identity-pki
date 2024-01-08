data "aws_caller_identity" "current" {}

data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

locals {
  aws_alias = trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")
}

# adding in both Data Stream and Firehose modules as methods of sending data to S3.
# TODO: investigate how each works and evaluate best possible option, based on
# things like load testing, data buffering, etc.

### DATA STREAM modules

module "logarchive_kinesis_primary" {
  source = "github.com/18F/identity-terraform//kinesis_stream_destination?ref=ced89307118740fa3729433f03ed57a5562106a2"
  #source = "../../../../identity-terraform/kinesis_stream_destination"
  providers = {
    aws = aws.usw2
  }

  stream_arn        = aws_kinesis_stream.logarchive.arn
  stream_region     = data.aws_region.current.name
  source_account_id = var.source_account_id
  role_name         = "${local.aws_alias}-kinesis-${data.aws_region.current.name}"
}

# create Destination in us-east-1 which points to Kinesis Stream in us-west-2
module "logarchive_kinesis_secondary" {
  count  = length(var.secondary_region) != 0 ? 1 : 0
  source = "github.com/18F/identity-terraform//kinesis_stream_destination?ref=ced89307118740fa3729433f03ed57a5562106a2"
  #source = "../../../../identity-terraform/kinesis_stream_destination"
  providers = {
    aws = aws.use1
  }

  stream_arn        = aws_kinesis_stream.logarchive.arn
  stream_region     = data.aws_region.current.name
  source_account_id = var.source_account_id
  role_name         = "${local.aws_alias}-kinesis-${var.secondary_region}"
}

### FIREHOSE modules

module "logarchive_firehose_primary" {
  source = "github.com/18F/identity-terraform//kinesis_firehose_destination?ref=ced89307118740fa3729433f03ed57a5562106a2"
  #source = "../../../../identity-terraform/kinesis_firehose_destination"
  providers = {
    aws = aws.usw2
  }

  firehose_arn      = aws_kinesis_firehose_delivery_stream.logarchive.arn
  firehose_region   = data.aws_region.current.name
  source_account_id = var.source_account_id
  role_name         = "${local.aws_alias}-firehose-${data.aws_region.current.name}"
}

# create Destination in us-east-1 which points to Firehose in us-west-2
module "logarchive_firehose_secondary" {
  count  = length(var.secondary_region) != 0 ? 1 : 0
  source = "github.com/18F/identity-terraform//kinesis_firehose_destination?ref=ced89307118740fa3729433f03ed57a5562106a2"
  #source = "../../../../identity-terraform/kinesis_firehose_destination"
  providers = {
    aws = aws.use1
  }

  firehose_arn      = aws_kinesis_firehose_delivery_stream.logarchive.arn
  firehose_region   = data.aws_region.current.name
  source_account_id = var.source_account_id
  role_name         = "${local.aws_alias}-firehose-${var.secondary_region}"
}
