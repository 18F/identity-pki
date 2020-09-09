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
