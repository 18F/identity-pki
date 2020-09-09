# Terraform reference for old log buckets, to track them in state
resource "aws_s3_bucket" "legacy_log_bucket" {
  count = var.keep_legacy_bucket ? 1 : 0

  bucket = "login-gov-${var.env_name}-logs"
  force_destroy = true
  acl = "log-delivery-write"

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "/${var.env_name}/s3-access-logs/login-gov-${var.env_name}-logs/"
  }

  tags = {
    Name = "login-gov-${var.env_name}-logs"
  }

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

    noncurrent_version_transition {
      days = 90 
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days = 365
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 2190
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_scrub_bucket" {
  depends_on = [aws_s3_bucket.log_scrub_bucket]

  bucket                  = aws_s3_bucket.log_scrub_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
