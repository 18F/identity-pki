module "transfer_utility" {
  source             = "../../modules/transfer_bucket"
  bucket_name        = "transfer-utility"
  logs_bucket        = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  bucket_name_prefix = local.bucket_name_prefix
  force_destroy      = true
}
