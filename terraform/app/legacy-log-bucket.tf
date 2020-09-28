# Terraform reference for old log buckets, to track them in state

resource "aws_s3_bucket" "legacy_log_bucket" {
  count = var.keep_legacy_bucket ? 1 : 0

  bucket = "login-gov-${var.env_name}-logs"
  force_destroy = true
  acl = "log-delivery-write"  

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "logexpire"
    enabled = true
    prefix  = ""

    transition {
      days = 90
      storage_class = "STANDARD_IA" 
    }

    transition {
      days = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190
    }
  }
}

module "legacy_log_bucket_config" {
  count  = var.keep_legacy_bucket ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=36ecdc74c3436585568fab7abddb3336cec35d93"

  bucket_name_override = aws_s3_bucket.legacy_log_bucket[0].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
