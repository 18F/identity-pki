# These modules are for TEMPORARY use while cleanup/audit work is performed on the S3 buckets in our core accounts.
# https://github.com/18F/identity-devops/issues/2657

module "s3_inventory_uw2" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source = "../../../../identity-terraform/s3_batch_inventory"

  bucket_list          = var.bucket_list_uw2
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
}

module "s3_config_ue1" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source = "../../../../identity-terraform/state_bucket"
  providers = {
    aws = aws.use1
  }

  remote_state_enabled = 0
  region               = "us-east-1"
  bucket_name_prefix   = "login-gov"
  sse_algorithm        = "AES256"
}

module "s3_inventory_ue1" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source   = "../../../../identity-terraform/s3_batch_inventory"
  providers = {
    aws = aws.use1
  }

  bucket_list          = var.bucket_list_ue1
  inventory_bucket_arn = module.s3_config_ue1.inventory_bucket_arn
}
