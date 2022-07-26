resource "aws_s3_bucket" "guardduty_threat_feed_s3_bucket" {
  bucket = local.gd_s3_bucket
  tags = {
    feed = var.guardduty_threat_feed_name
  }
}

resource "aws_s3_bucket_acl" "guardduty_threat_feed_s3_bucket" {
  bucket = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "guardduty_threat_feed_s3_bucket" {
  bucket = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty_threat_feed_s3_bucket" {
  bucket = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "guardduty_threat_feed_s3_bucket" {
  bucket = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id

  target_bucket = var.logs_bucket
  target_prefix = "${local.gd_s3_bucket}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "guardduty_threat_feed_s3_bucket" {
  bucket = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id

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

module "guardduty_threat_feed_s3_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  bucket_name_override = aws_s3_bucket.guardduty_threat_feed_s3_bucket.id
  inventory_bucket_arn = var.inventory_bucket_arn
}
