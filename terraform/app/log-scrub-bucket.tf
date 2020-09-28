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
        # CloudWatch export to S3 does not support KMS
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = false
  }

}

module "log_scrub_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=36ecdc74c3436585568fab7abddb3336cec35d93"

  bucket_name_override = aws_s3_bucket.log_scrub_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

data "aws_iam_policy_document" "log_scrub_bucket_write_policy" {
  # Allow CloudWatch to export logs to this bucket
  statement {
    sid = "allowCloudWatchGetAcl"
    actions = [
      "s3:GetBucketAcl",
    ]
    principals {
      type = "Service"
      identifiers = [
        "logs.${var.region}.amazonaws.com",
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }

  statement {
    sid = "allowCloudWatchPutObject"
    actions = [
      "s3:PutObject",
    ]
    principals {
      type = "Service"
      identifiers = [
        "logs.${var.region}.amazonaws.com",
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control",
      ]
    }
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
      "arn:aws:s3:::login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-log-scrub-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}
