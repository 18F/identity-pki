# per-env objects to add to secrets/app-secrets buckets

locals {
  app_dir_keys = [
    var.apps_enabled == 1 ? "dashboard" : "",
    "pivcac",
    "idp"
  ]
}

resource "aws_s3_bucket_object" "tfslackchannel" {
  bucket       = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key          = "${var.env_name}/tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "db_host_app" {
  count = var.apps_enabled

  bucket       = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key          = "${var.env_name}/db_host_app"
  content      = aws_db_instance.default[0].address
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "dir_key" {
  for_each = toset(compact(local.app_dir_keys))

  bucket = "login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${var.env_name}/${each.key}/v1/"
  source = "/dev/null"
}