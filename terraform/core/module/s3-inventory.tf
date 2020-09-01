# These modules are for TEMPORARY use while cleanup/audit work is performed on the S3 buckets in our core accounts.
# https://github.com/18F/identity-devops/issues/2657

module "s3_inventory_uw2" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=b4262465ff16c3287f2b8386dae7c0d4f6c641f7"
  #source = "../../../../identity-terraform/s3_batch_inventory"

  log_bucket   = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_uw2
}

module "s3_inventory_ue1" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=b4262465ff16c3287f2b8386dae7c0d4f6c641f7"
  #source = "../../../../identity-terraform/s3_batch_inventory"
  providers = {
    aws = aws.us-east-1
  }

  region = "us-east-1"
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_ue1
}
