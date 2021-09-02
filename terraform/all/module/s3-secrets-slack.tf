module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  #source = "../../../../identity-terraform/state_bucket"

  remote_state_enabled = 0
  region               = var.region
  bucket_name_prefix   = "login-gov"
  sse_algorithm        = "AES256"
}

module "main_secrets_bucket" {
  source     = "../../modules/secrets_bucket"
  depends_on = [module.tf-state.s3_log_bucket]

  bucket_name_prefix  = "login-gov"
  bucket_name         = "${local.bucket_name_prefix}.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_bucket         = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  secrets_bucket_type = local.secrets_bucket_type
  region              = var.region
}

resource "aws_s3_bucket_object" "tfslackchannel" {
  bucket       = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key          = "tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}
