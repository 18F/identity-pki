module "app_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  bucket_name         = "${local.bucket_name_prefix}.${local.app_secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_bucket         = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  secrets_bucket_type = local.app_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
}

output "app_secrets_bucket" {
  value = module.app_secrets_bucket.bucket_name
}

