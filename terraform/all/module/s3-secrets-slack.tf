# Terraform providers cannot be iterated on (via count/for_each),
# so we need a separate module for each region, at least for now.
# More info:
# https://github.com/hashicorp/terraform/issues/24476
# https://github.com/hashicorp/terraform/issues/25244

## us-west-2

module "tf_state_uw2" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=2d05076e1d089d9e9ab251fa0f11a2e2ceb132a3"
  #source = "../../../../identity-terraform/state_bucket"

  remote_state_enabled = 1
  region               = var.region
  bucket_name_prefix   = "login-gov"
  sse_algorithm        = "AES256"
}

module "main_secrets_bucket_uw2" {
  source     = "../../modules/secrets_bucket"
  depends_on = [module.tf_state_uw2.s3_access_log_bucket]

  bucket_name_prefix = "login-gov"
  bucket_name = join(".", [
    "${local.bucket_name_prefix}.secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  logs_bucket         = module.tf_state_uw2.s3_access_log_bucket
  secrets_bucket_type = local.secrets_bucket_type
  region              = var.region
}

resource "aws_s3_object" "tfslackchannel_uw2" {
  bucket       = module.main_secrets_bucket_uw2.bucket_name
  key          = "tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
  acl          = "private"
}

output "main_secrets_bucket_uw2" {
  value = module.main_secrets_bucket_uw2.bucket_name
}

## us-east-1

module "tf_state_ue1" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=2d05076e1d089d9e9ab251fa0f11a2e2ceb132a3"
  #source = "../../../../identity-terraform/state_bucket"
  providers = {
    aws = aws.use1
  }

  remote_state_enabled = 0 # no remote TF state table/bucket in us-east-1
  region               = "us-east-1"
  bucket_name_prefix   = "login-gov"
  sse_algorithm        = "AES256"
}

module "main_secrets_bucket_ue1" {
  source     = "../../modules/secrets_bucket"
  depends_on = [module.tf_state_ue1.s3_access_log_bucket]
  providers = {
    aws = aws.use1
  }

  bucket_name_prefix = "login-gov"
  bucket_name = join(".", [
    "${local.bucket_name_prefix}.secrets",
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  logs_bucket         = module.tf_state_ue1.s3_access_log_bucket
  secrets_bucket_type = local.secrets_bucket_type
  region              = "us-east-1"
}

resource "aws_s3_object" "tfslackchannel_ue1" {
  provider = aws.use1

  bucket       = module.main_secrets_bucket_ue1.bucket_name
  key          = "tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
  acl          = "private"
}

output "main_secrets_bucket_ue1" {
  value = module.main_secrets_bucket_ue1.bucket_name
}
