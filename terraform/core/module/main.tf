data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

locals {
  aws_alias = trimprefix(
    data.aws_iam_account_alias.current.account_alias, "login-"
  )
  bucket_name_prefix        = "login-gov"
  app_secrets_bucket_type   = "app-secrets"
  cert_secrets_bucket_type  = "internal-certs"
  app_artifacts_bucket_type = "app-artifacts"
  inventory_bucket_uw2_arn  = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-us-west-2"
  inventory_bucket_ue1_arn  = "arn:aws:s3:::${local.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-us-east-1"
  s3_logs_bucket_uw2        = "${local.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-us-west-2"
  s3_logs_bucket_ue1        = "${local.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-us-east-1"
  dnssec_runbook_prefix     = " - https://gitlab.login.gov/lg/identity-devops/-/wikis/Runbook:-DNS#dnssec"
}

data "aws_s3_bucket" "s3_logs_bucket_uw2" {
  bucket = local.s3_logs_bucket_uw2
}
