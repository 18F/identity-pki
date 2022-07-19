module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=cf0896394f38f0bd0e79054f2d413be2de1b2dd9"
  #source = "../../../../identity-terraform/state_bucket"

  remote_state_enabled = 1
  region               = var.region
  bucket_name_prefix   = "login-gov"
  sse_algorithm        = "AES256"
}

module "main_secrets_bucket" {
  source     = "../../modules/secrets_bucket"
  depends_on = [module.tf-state.s3_access_log_bucket]

  bucket_name_prefix  = "login-gov"
  bucket_name         = "${local.bucket_name_prefix}.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_bucket         = module.tf-state.s3_access_log_bucket
  secrets_bucket_type = local.secrets_bucket_type
  region              = var.region
}

resource "aws_s3_object" "tfslackchannel" {
  bucket       = module.main_secrets_bucket.bucket_name
  key          = "tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}
