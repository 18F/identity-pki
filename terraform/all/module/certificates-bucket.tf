module "internal_certificates_bucket" {
  source              = "../../modules/secrets_bucket"
  bucket_name         = "${local.bucket_name_prefix}.${local.cert_secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_bucket         = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  secrets_bucket_type = local.cert_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
}
