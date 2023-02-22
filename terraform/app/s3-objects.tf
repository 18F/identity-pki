# per-env objects to add to secrets/app-secrets buckets

locals {
  app_dir_keys = [
    var.apps_enabled == 1 ? "dashboard" : "",
    "pivcac",
    "idp"
  ]
}

resource "aws_s3_object" "tfslackchannel" {
  bucket       = data.aws_s3_bucket.secrets.bucket
  key          = "${var.env_name}/tfslackchannel"
  content      = var.tf_slack_channel
  content_type = "text/plain"
}

resource "aws_s3_object" "db_host_app" {
  count = var.apps_enabled

  bucket       = data.aws_s3_bucket.secrets.bucket
  key          = "${var.env_name}/db_host_app"
  content      = module.dashboard_aurora_uw2[count.index].writer_endpoint
  content_type = "text/plain"
}

resource "aws_s3_object" "dir_key" {
  for_each = toset(compact(local.app_dir_keys))

  bucket = data.aws_s3_bucket.app_secrets.bucket
  key    = "${var.env_name}/${each.key}/v1/"
  source = "/dev/null"
}