module "internal_certificates_bucket" {
  source              = "../../modules/secrets_bucket"
  bucket_name         = "${local.bucket_name_prefix}.${local.cert_secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_bucket         = local.s3_logs_bucket
  secrets_bucket_type = local.cert_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
}
