module "app_artifacts_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = local.s3_logs_bucket
  secrets_bucket_type = local.app_artifacts_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  bucket_name         = "${local.bucket_name_prefix}.${local.app_artifacts_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy       = true
}

output "app_artifacts_bucket" {
  value = module.app_artifacts_bucket.bucket_name
}

