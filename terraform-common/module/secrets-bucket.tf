# Create the main citadel secrets bucket
module "main_secrets_bucket" {
  source              = "../../terraform-modules/secrets_bucket"
  logs_bucket         = aws_s3_bucket.s3-logs.id
  secrets_bucket_type = "secrets"
  bucket_name_prefix  = "login-gov"
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}

