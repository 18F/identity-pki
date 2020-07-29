module "app_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = module.s3_shared_uw2.log_bucket
  secrets_bucket_type = "app-secrets"
  bucket_name_prefix  = "login-gov"
  force_destroy       = true
}

output "app_secrets_bucket" {
  value = module.app_secrets_bucket.bucket_name
}

