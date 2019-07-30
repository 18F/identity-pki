module "internal_certificates_bucket" {
    source = "../terraform-modules/secrets_bucket"
    logs_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    secrets_bucket_type = "internal-certs"
    bucket_name_prefix = "login-gov"
    force_destroy = true
}
