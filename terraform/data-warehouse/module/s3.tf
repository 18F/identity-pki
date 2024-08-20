resource "aws_s3_bucket" "analytics_import" {
  bucket = join("-", [
    "login-gov-redshift-import-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

locals {
  query_roles = [
    "FullAdministrator",
    "Terraform",
    "AutoTerraform",
  ]
}

resource "aws_s3_bucket_ownership_controls" "analytics_import" {
  bucket = aws_s3_bucket.analytics_import.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "analytics_import" {
  bucket = aws_s3_bucket.analytics_import.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_import]
}

resource "aws_s3_bucket_logging" "analytics_import" {
  bucket        = aws_s3_bucket.analytics_import.id
  target_bucket = data.aws_s3_bucket.access_logging.id
  target_prefix = "${aws_s3_bucket.analytics_import.bucket}/"
}

resource "aws_s3_bucket_public_access_block" "analytics_import" {
  bucket = aws_s3_bucket.analytics_import.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_import" {
  bucket = aws_s3_bucket.analytics_import.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.redshift_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "analytics_import" {
  bucket = aws_s3_bucket.analytics_import.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.analytics_import.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.login_account_id}:role/login-gov-${var.env_name}-analytics-replication"
      ]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:PutObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = [
      "${aws_s3_bucket.analytics_import.arn}/*"
    ]
  }
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.analytics_import.arn,
      "${aws_s3_bucket.analytics_import.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket" "analytics_export" {
  bucket = join("-", [
    "login-gov-analytics-export-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket_ownership_controls" "analytics_export" {
  bucket = aws_s3_bucket.analytics_export.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "analytics_export" {
  bucket = aws_s3_bucket.analytics_export.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_export]
}

resource "aws_s3_bucket_logging" "analytics_export" {
  bucket        = aws_s3_bucket.analytics_export.id
  target_bucket = data.aws_s3_bucket.access_logging.id
  target_prefix = "${aws_s3_bucket.analytics_export.bucket}/"
}

resource "aws_s3_bucket_public_access_block" "analytics_export" {
  bucket = aws_s3_bucket.analytics_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_export" {
  bucket = aws_s3_bucket.analytics_export.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.redshift_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "analytics_export" {
  bucket = aws_s3_bucket.analytics_export.id
  policy = data.aws_iam_policy_document.analytics_export_require_secure_connections.json
}

data "aws_iam_policy_document" "analytics_export_require_secure_connections" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.analytics_export.arn,
      "${aws_s3_bucket.analytics_export.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket" "analytics_logs" {
  bucket = join("-", [
    "login-gov-redshift-${var.env_name}-logs",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

resource "aws_s3_bucket_ownership_controls" "analytics_logs" {
  bucket = aws_s3_bucket.analytics_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "analytics_logs" {
  bucket = aws_s3_bucket.analytics_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.analytics_logs]
}

resource "aws_s3_bucket_logging" "analytics_logs" {
  bucket        = aws_s3_bucket.analytics_logs.id
  target_bucket = data.aws_s3_bucket.access_logging.id
  target_prefix = "${aws_s3_bucket.analytics_logs.bucket}/"
}

resource "aws_s3_bucket_public_access_block" "analytics_logs" {
  bucket = aws_s3_bucket.analytics_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_logs" {
  bucket = aws_s3_bucket.analytics_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.redshift_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "bucket_policy_json" {
  statement {
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.analytics_logs.arn,
      "${aws_s3_bucket.analytics_logs.arn}/*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.redshift_role.arn,
      ]
    }
  }
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.analytics_logs.arn,
      "${aws_s3_bucket.analytics_logs.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "redshift_logs_policy" {
  bucket = aws_s3_bucket.analytics_logs.id
  policy = data.aws_iam_policy_document.bucket_policy_json.json
}
