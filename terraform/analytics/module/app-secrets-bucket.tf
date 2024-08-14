module "app_secrets_bucket_uw2" {
  providers = {
    aws = aws.usw2
  }
  source = "../../modules/secrets_bucket"
  bucket_name = join(".", [
    local.bucket_name_prefix, local.app_secrets_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-west-2"
  ])
  logs_bucket = join(".", [
    "${local.bucket_name_prefix}.s3-access-logs",
    "${data.aws_caller_identity.current.account_id}-us-west-2"
  ])
  secrets_bucket_type = local.app_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
  region              = "us-west-2"
}

module "app_secrets_bucket_ue1" {
  source = "../../modules/secrets_bucket"
  providers = {
    aws = aws.use1
  }

  bucket_name = join(".", [
    local.bucket_name_prefix, local.app_secrets_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  logs_bucket = join(".", [
    "${local.bucket_name_prefix}.s3-access-logs",
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  secrets_bucket_type = local.app_secrets_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  force_destroy       = true
  region              = "us-east-1"
}

