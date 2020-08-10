# Temporary S3 bucket for log cleaning
resource "aws_s3_bucket" "log_scrub_bucket" {
  bucket = "login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"

  force_destroy = true

  logging {
    target_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "/${var.env_name}/s3-access-logs/login-gov-log-scrub/"
  }

  tags = {
    Name = "login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  }

  policy = data.aws_iam_policy_document.log_scrub_bucket_write_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = false
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

data "aws_iam_policy_document" "log_scrub_bucket_write_policy" {
  # Allow CloudWatch to export logs to this bucket
  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    principals {
      type = "Service"
      identifiers = [
        "logs.${var.region}.amazonaws.com"
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    principals {
      type = "Service"
      identifiers = [
        "logs.${var.region}.amazonaws.com"
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}

# Policy document for use with roles that should have read only access to bucket
data "aws_iam_policy_document" "log_scrub_bucket_read_policy" {
  statement {
    sid = "allowReadLogScrubBucket"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
