locals {
  s3_inventory_bucket_arn = join(".", [
    "arn:aws:s3:::login-gov.s3-inventory",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  waf_bucket = join(".", [
    "login-gov.${local.web_acl_name}-logs",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  access_logs_bucket = join(".", [
    "login-gov.s3-access-logs",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket" "waf_logs" {
  bucket = local.waf_bucket
  tags = {
    environment = var.env
  }
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.waf_logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "waf_logs" {
  bucket        = aws_s3_bucket.waf_logs.id
  target_bucket = local.access_logs_bucket
  target_prefix = "${local.waf_bucket}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expire"
    status = "Enabled"
    filter {
      prefix = "/"
    }

    transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    expiration {
      days = 2190
    }
    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "waf_log_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=0b68909c0c2ca3ed84912616f3f97d0f98bcd65b"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.waf_logs.id
  inventory_bucket_arn = local.s3_inventory_bucket_arn
}


resource "aws_cloudwatch_log_group" "cw_waf_logs" {
  name              = "aws-waf-logs-${local.web_acl_name}" # must start w/ "aws-waf-logs"
  retention_in_days = 365
}

module "log-ship-to-soc-waf-logs" {
  count                               = var.ship_logs_to_soc ? 1 : 0
  source                              = "../../modules/log_ship_to_soc"
  region                              = var.region
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    tostring(aws_cloudwatch_log_group.cw_waf_logs.name) = ""
  }
  env_name = var.lb_name != "" ? (
  "${var.lb_name}-waf") : "${var.env}-idp-waf-${var.wafv2_web_acl_scope}"
  soc_destination_arn = var.soc_destination_arn
}
