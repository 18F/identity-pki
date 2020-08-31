# Create the main citadel secrets bucket
module "s3_inventory_uw2" {
  #source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=64b13f0a31973112e02aabed4ccc8774dc6e2bab"
  source = "../../../../identity-terraform/s3_batch_inventory"

  log_bucket   = module.s3_shared.log_bucket
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_uw2
}

module "s3_inventory_ue1" {
  #source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=64b13f0a31973112e02aabed4ccc8774dc6e2bab"
  source = "../../../../identity-terraform/s3_batch_inventory"
  providers = {
    aws = aws.us-east-1
  }

  region = "us-east-1"
  log_bucket   = module.s3_shared.log_bucket
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_ue1
}
