data "aws_caller_identity" "current" {
}

locals {
  bucket_name_prefix       = "login-gov"
  app_secrets_bucket_type  = "app-secrets"
  inventory_bucket_uw2_arn = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-us-west-2"
}

