# Terraform reference for old log buckets, to track them in state

resource "aws_s3_bucket" "legacy_log_bucket" {
  count = var.keep_legacy_bucket ? 1 : 0

  bucket        = "login-gov-${var.env_name}-logs"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "legacy_log_bucket" {
  count  = var.keep_legacy_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_bucket[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "legacy_log_bucket" {
  count  = var.keep_legacy_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_bucket[count.index].id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.legacy_log_bucket]
}

resource "aws_s3_bucket_versioning" "legacy_log_bucket" {
  count  = var.keep_legacy_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_bucket[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "legacy_log_bucket" {
  count  = var.keep_legacy_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "legacy_log_bucket" {
  count  = var.keep_legacy_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_bucket[count.index].id

  rule {
    id     = "logexpire"
    status = "Enabled"
    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190
    }
  }
}

module "legacy_log_bucket_config" {
  count  = var.keep_legacy_bucket ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.legacy_log_bucket[count.index].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
