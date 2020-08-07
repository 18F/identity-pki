module "app_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  secrets_bucket_type = "app-secrets"
  bucket_name_prefix  = "login-gov"
  force_destroy       = true
}

output "app_secrets_bucket" {
  value = module.app_secrets_bucket.bucket_name
}

