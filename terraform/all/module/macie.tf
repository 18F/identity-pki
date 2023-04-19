# Creates the S3 buckets and KMS CMK required to enable Macie2 in every
# account. This does not imply that Macie2 will be enabled in every account,
# only that the resources exist.

locals {
  macie_s3_bucket_name = "login-gov.awsmacietrail-dataevent.${data.aws_caller_identity.current.account_id}-${var.region}"
}

# KMS key/alias

resource "aws_kms_key" "awsmacietrail_dataevent" {
  description             = "Macie v2"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_awsmacietrail_dataevent.json
}

resource "aws_kms_alias" "awsmacietrail_dataevent" {
  name          = "alias/awsmacietrail-dataevent"
  target_key_id = aws_kms_key.awsmacietrail_dataevent.key_id
}

# S3 resources

resource "aws_s3_bucket" "awsmacietrail_dataevent" {
  bucket = local.macie_s3_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.awsmacietrail_dataevent]
}

resource "aws_s3_bucket_versioning" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.awsmacietrail_dataevent.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.id
  policy = data.aws_iam_policy_document.s3_awsmacietrail_dataevent.json
}

resource "aws_s3_bucket_logging" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.id

  target_bucket = module.tf-state.s3_access_log_bucket
  target_prefix = "${local.macie_s3_bucket_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "awsmacietrail_dataevent" {
  bucket = aws_s3_bucket.awsmacietrail_dataevent.id

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

# Recommended policies per the Macie console

data "aws_iam_policy_document" "kms_awsmacietrail_dataevent" {
  statement {
    sid    = "Allow Macie to use the key"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "macie.amazonaws.com"
      ]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "Allow root to administer the key. This enables IAM policies."
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "s3_awsmacietrail_dataevent" {
  statement {
    sid    = "Deny non-HTTPS access"
    effect = "Deny"
    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${local.macie_s3_bucket_name}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
  statement {
    sid    = "Allow encrypted Macie uploads."
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "macie.amazonaws.com"
      ]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.macie_s3_bucket_name}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values = [
        aws_kms_key.awsmacietrail_dataevent.arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms"
      ]
    }
  }
  statement {
    sid    = "Allow Macie to use the getBucketLocation operation"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "macie.amazonaws.com"
      ]
    }
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${local.macie_s3_bucket_name}"
    ]
  }
}
