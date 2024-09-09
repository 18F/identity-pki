locals {
  config_recorder_s3_bucket_name = "config-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "config_recorder" {
  bucket        = local.config_recorder_s3_bucket_name
  force_destroy = true

  tags = {
    Name = local.config_recorder_s3_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.config_recorder]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id

  target_bucket = module.tf_state_uw2.s3_access_log_bucket
  target_prefix = "${local.config_recorder_s3_bucket_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id

  rule {
    id     = "intelligent"
    status = "Enabled"
    filter {
      prefix = "/"
    }

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "INTELLIGENT_TIERING"
    }
    expiration {
      days = 2190
    }
    noncurrent_version_expiration {
      noncurrent_days = 2190
    }
  }
}

module "config_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.config_recorder.id
  inventory_bucket_arn = module.tf_state_uw2.inventory_bucket_arn
}

resource "aws_s3_bucket_policy" "config_recorder" {
  depends_on = [aws_s3_bucket.config_recorder]
  bucket     = aws_s3_bucket.config_recorder.id
  policy     = data.aws_iam_policy_document.config_recorder_bucket_policy.json
}

data "aws_iam_policy_document" "config_recorder_bucket_policy" {
  statement {
    sid       = "AWSConfigBucketPermissionsCheck"
    effect    = "Allow"
    resources = [aws_s3_bucket.config_recorder.arn]
    actions   = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSConfigBucketExistenceCheck"
    effect    = "Allow"
    resources = [aws_s3_bucket.config_recorder.arn]
    actions   = ["s3:ListBucket"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSConfigBucketDelivery"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config_recorder.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid = "S3DenyNonSecureConnections"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      aws_s3_bucket.config_recorder.arn,
      "${aws_s3_bucket.config_recorder.arn}/*"
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_config_configuration_recorder" "default" {
  name     = "default"
  role_arn = aws_iam_role.config_recorder.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config_recorder" {
  name               = "config-role-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.config_recorder_assume.json
}

data "aws_iam_policy_document" "config_recorder_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_recorder_managed_policy" {
  role       = aws_iam_role.config_recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_policy" "config_recorder_s3" {
  name        = "ConfigRecorderPolicy"
  description = "Policy to allow s3 changes to be recorded"
  policy      = data.aws_iam_policy_document.config_recorder_s3.json
}

resource "aws_iam_role_policy_attachment" "config_recorder_s3_policy" {
  role       = aws_iam_role.config_recorder.name
  policy_arn = aws_iam_policy.config_recorder_s3.arn
}

data "aws_iam_policy_document" "config_recorder_s3" {
  statement {
    sid    = "s3put"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.config_recorder_s3_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
  statement {
    sid    = "s3acl"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.config_recorder_s3_bucket_name}"
    ]
  }
}

resource "aws_config_delivery_channel" "default" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_recorder.id
  depends_on     = [aws_config_configuration_recorder.default]
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
}

resource "aws_config_configuration_recorder_status" "default" {
  name       = aws_config_configuration_recorder.default.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.default]
}

resource "aws_securityhub_account" "default" {
  depends_on = [aws_config_configuration_recorder_status.default]
}

resource "aws_securityhub_standards_subscription" "nist_800_53" {
  depends_on    = [aws_securityhub_account.default]
  standards_arn = "arn:aws:securityhub:${var.region}::standards/nist-800-53/v/5.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.default]
  standards_arn = "arn:aws:securityhub:${var.region}::standards/cis-aws-foundations-benchmark/v/3.0.0"
}

resource "aws_securityhub_standards_subscription" "foundational_best_practices" {
  depends_on    = [aws_securityhub_account.default]
  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}
