locals {
  bucket_name_prefix        = "login-gov"
  app_secrets_bucket_type   = "app-secrets"
  cert_secrets_bucket_type  = "internal-certs"
  app_artifacts_bucket_type = "app-artifacts"
  inventory_bucket_uw2_arn  = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-us-west-2"
  inventory_bucket_ue1_arn  = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-us-east-1"
  s3_logs_bucket_uw2        = "${local.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-us-west-2"
  s3_logs_bucket_ue1        = "${local.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-us-east-1"
  dnssec_runbook_prefix     = " - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec"
}
