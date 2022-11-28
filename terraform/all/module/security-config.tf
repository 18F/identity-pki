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

resource "aws_s3_bucket_acl" "config_recorder" {
  bucket = aws_s3_bucket.config_recorder.id
  acl    = "private"
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

  target_bucket = module.tf-state.s3_access_log_bucket
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
  source = "github.com/18F/identity-terraform//s3_config?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  bucket_name_override = aws_s3_bucket.config_recorder.id
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}

resource "aws_s3_bucket_policy" "config_recorder" {
  depends_on = [aws_s3_bucket.config_recorder]
  bucket     = aws_s3_bucket.config_recorder.id
  policy     = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSConfigBucketPermissionsCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.config_recorder_s3_bucket_name}"
        },
                {
            "Sid": "AWSConfigBucketExistenceCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${local.config_recorder_s3_bucket_name}"
        },
        {
            "Sid": "AWSConfigBucketDelivery",
            "Effect": "Allow",
            "Principal": {
                "Service": "config.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.config_recorder_s3_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
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
