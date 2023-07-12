module "internal_certificates_bucket_uw2" {
  source = "../../modules/secrets_bucket"
  bucket_name = join(".", [
    local.bucket_name_prefix, local.cert_secrets_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-west-2"
  ])
  logs_bucket         = module.tf_state_uw2.s3_access_log_bucket
  secrets_bucket_type = local.cert_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
  region              = "us-west-2"
}

moved {
  from = module.internal_certificates_bucket
  to   = module.internal_certificates_bucket_uw2
}

module "internal_certificates_bucket_ue1" {
  source = "../../modules/secrets_bucket"
  providers = {
    aws = aws.use1
  }

  bucket_name = join(".", [
    local.bucket_name_prefix, local.cert_secrets_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  logs_bucket         = module.tf_state_ue1.s3_access_log_bucket
  secrets_bucket_type = local.cert_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
  region              = "us-east-1"
}
