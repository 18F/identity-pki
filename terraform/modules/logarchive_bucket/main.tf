##### Variables

locals {
  aws_alias = var.archive_type == "" ? (
    trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")) : (
    "${var.archive_type}-${trimprefix(data.aws_iam_account_alias.current.account_alias, "login-log")}"
  )

  bucket_name = join(".", [
    "login-gov.${local.aws_alias}",
    "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  ])

  s3_inventory_bucket_arn = join(".", [
    "arn:aws:s3:::login-gov.s3-inventory",
    "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  ])

  access_logs_bucket = join(".", [
    "login-gov.s3-access-logs",
    "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  ])
}

variable "kms_key_id" {
  type        = string
  description = "Key ID of the KMS key used for aws:kms encryption"
}

variable "archive_type" {
  type        = string
  description = "Type of archive bucket"
  default     = ""
}

##### Data Sources

data "aws_caller_identity" "current" {}

data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

##### Resources

resource "aws_s3_bucket" "logarchive" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id

  rule {
    id     = "logexpire"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = 180
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

resource "aws_s3_bucket_logging" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id

  target_bucket = local.access_logs_bucket
  target_prefix = "${aws_s3_bucket.logarchive.id}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logarchive" {
  bucket = aws_s3_bucket.logarchive.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.logarchive]
}

module "bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=0b68909c0c2ca3ed84912616f3f97d0f98bcd65b"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.logarchive.id
  inventory_bucket_arn = local.s3_inventory_bucket_arn
}

##### Outputs

output "bucket_name" {
  value       = aws_s3_bucket.logarchive.id
  description = "Name/ID of the logarchive S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.logarchive.arn
  description = "ARN of the logarchive S3 bucket."
}

output "bucket_region" {
  value       = aws_s3_bucket.logarchive.region
  description = "Region of the logarchive S3 bucket."
}
