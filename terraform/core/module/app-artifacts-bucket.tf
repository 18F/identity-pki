#cross_account_archive_bucket_access = {thing = [directories]}
# BUCKETNAME/KEY
#
#
# #cross_account_archive_bucket_access = {
#    "arn:aws:iam::12341231:role/alpha-test-pool_gitlab_runner_iam_role" = [
#       "login-gov.app-artifacts.894947205914-us-west-2/mhenke",
#       "login-gov.app-artifacts.894947205914-us-west-2/"
data "aws_iam_policy_document" "app_artifacts_cross_account" {
  for_each = toset(["us-west-2", "us-east-1"])

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
        for subdir in statement.value : join("", [
          "arn:aws:s3:::",
          "${local.bucket_name_prefix}.${local.app_artifacts_bucket_type}.",
          "${data.aws_caller_identity.current.account_id}-${each.key}/${subdir}/*"
        ])
      ]
    }
  }
}

module "app_artifacts_bucket_uw2" {
  source              = "../../modules/secrets_bucket"
  logs_bucket         = local.s3_logs_bucket_uw2
  secrets_bucket_type = local.app_artifacts_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  bucket_name = join(".", [
    local.bucket_name_prefix, local.app_artifacts_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-west-2"
  ])
  force_destroy    = true
  sse_algorithm    = "AES256"
  object_ownership = "BucketOwnerEnforced"
  policy = length(
    var.cross_account_archive_bucket_access
  ) > 0 ? data.aws_iam_policy_document.app_artifacts_cross_account["us-west-2"].json : ""
  region = "us-west-2"
}

output "app_artifacts_bucket_uw2" {
  value = module.app_artifacts_bucket_uw2.bucket_name
}

module "app_artifacts_bucket_ue1" {
  source = "../../modules/secrets_bucket"
  providers = {
    aws = aws.use1
  }

  logs_bucket         = local.s3_logs_bucket_ue1
  secrets_bucket_type = local.app_artifacts_bucket_type
  bucket_name_prefix  = local.bucket_name_prefix
  bucket_name = join(".", [
    local.bucket_name_prefix, local.app_artifacts_bucket_type,
    "${data.aws_caller_identity.current.account_id}-us-east-1"
  ])
  force_destroy    = true
  sse_algorithm    = "AES256"
  object_ownership = "BucketOwnerEnforced"
  policy = length(
    var.cross_account_archive_bucket_access
  ) > 0 ? data.aws_iam_policy_document.app_artifacts_cross_account["us-east-1"].json : ""
  region = "us-east-1"
}

output "app_artifacts_bucket_ue1" {
  value = module.app_artifacts_bucket_ue1.bucket_name
}
