locals {
  bucket_name_prefix        = "login-gov"
  app_secrets_bucket_type   = "app-secrets"
  cert_secrets_bucket_type  = "internal-certs"
  app_artifacts_bucket_type = "app-artifacts"
  inventory_bucket_uw2_arn  = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
  s3_logs_bucket            = "${local.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
}
