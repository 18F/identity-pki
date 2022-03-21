locals {
  bucket_name = "${local.bucket_name_prefix}.${local.app_artifacts_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

#cross_account_archive_bucket_access = {thing = [directories]}
# BUCKETNAME/KEY
#
#
# #cross_account_archive_bucket_access = {
#    "arn:aws:iam::12341231:role/alpha-test-pool_gitlab_runner_iam_role" = [
#       "login-gov.app-artifacts.894947205914-us-west-2/mhenke",
#       "login-gov.app-artifacts.894947205914-us-west-2/"
data "aws_iam_policy_document" "app_artifacts_cross_account" {
  dynamic "statement" {
    for_each = var.cross_account_archive_bucket_access

    content {
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      principals {
        type = "AWS"
        identifiers = [
          statement.key
        ]
      }
      resources = [
        for subdir in statement.value : "arn:aws:s3:::${local.bucket_name}/${subdir}/*"
      ]
    }
  }
}

module "app_artifacts_bucket" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = local.s3_logs_bucket
  secrets_bucket_type = local.app_artifacts_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  bucket_name         = local.bucket_name
  force_destroy       = true
  sse_algorithm       = "AES256"
  policy              = data.aws_iam_policy_document.app_artifacts_cross_account.json
}

resource "aws_s3_bucket_ownership_controls" "artifacts_bucket" {
  bucket = module.app_artifacts_bucket.bucket_name

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

output "app_artifacts_bucket" {
  value = module.app_artifacts_bucket.bucket_name
}
