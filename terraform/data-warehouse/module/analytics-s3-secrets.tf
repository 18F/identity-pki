locals {
  bucket_name_prefix = "login-gov"
}

data "aws_s3_bucket" "app_secrets" {
  bucket = join(".", [
    local.bucket_name_prefix, "app-secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_object" "analytics_folder" {
  bucket = data.aws_s3_bucket.app_secrets.id
  acl    = "private"
  key    = "${var.env_name}/analytics/v1/"
}
