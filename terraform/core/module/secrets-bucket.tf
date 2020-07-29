# Create the main citadel secrets bucket
module "main_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = module.s3_shared_uw2.log_bucket
  secrets_bucket_type = "secrets"
  bucket_name_prefix  = "login-gov"
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}

