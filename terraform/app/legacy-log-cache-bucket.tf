# Terraform reference for deprecated login-gov-log-cache buckets,
# previously used by the send_logs_to_s3 module and corresponding
# cw-kinesis-s3-idp-events Kinesis Firehose Stream/CloudWatch Subscription Filter.
# Set var.keep_log_cache_bucket to 1 in order to preserve these resources.
# Should ONLY be done for upper environments; phase out once logs have been
# moved to logarchive account(s) via S3 Export Tasks.

data "aws_iam_policy_document" "legacy_log_cache_kms" {
  count = var.keep_log_cache_bucket ? 1 : 0
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*",
    ]
  }
}

resource "aws_cloudwatch_log_group" "legacy_log_cache" {
  count = var.keep_log_cache_bucket ? 1 : 0
  name  = "/aws/kinesisfirehose/cw-kinesis-s3-${var.env_name}-${var.region}"
}

resource "aws_cloudwatch_log_stream" "legacy_log_cache" {
  count          = var.keep_log_cache_bucket ? 1 : 0
  log_group_name = aws_cloudwatch_log_group.legacy_log_cache[count.index].name
  name           = "S3Delivery"
}

resource "aws_kms_key" "legacy_log_cache" {
  count                   = var.keep_log_cache_bucket ? 1 : 0
  description             = "KMS key for login-gov-log-cache-${var.env_name} S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.legacy_log_cache_kms[count.index].json

  depends_on = [aws_s3_bucket.legacy_log_cache]
}

resource "aws_kms_alias" "legacy_log_cache" {
  count         = var.keep_log_cache_bucket ? 1 : 0
  name          = "alias/${var.env_name}-kms-s3-log-cache-bucket"
  target_key_id = aws_kms_key.legacy_log_cache[count.index].key_id
}

resource "aws_s3_bucket" "legacy_log_cache" {
  count = var.keep_log_cache_bucket ? 1 : 0
  bucket = join(".", [
    "login-gov-log-cache-${var.env_name}",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "legacy_log_cache" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_cache[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "legacy_log_cache" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_cache[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.legacy_log_cache]
}

resource "aws_s3_bucket_versioning" "legacy_log_cache" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_cache[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "legacy_log_cache" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_cache[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.legacy_log_cache[count.index].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "legacy_log_cache" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  bucket = aws_s3_bucket.legacy_log_cache[count.index].id

  rule {
    id     = "logexpire"
    status = "Enabled"
    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190
    }
  }
}

module "legacy_log_cache_bucket_config" {
  count  = var.keep_log_cache_bucket ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_override = aws_s3_bucket.legacy_log_cache[count.index].id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

##### REMOVE once moves are finished #####

moved {
  from = module.kinesis-firehose.aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group
  to   = aws_cloudwatch_log_group.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream
  to   = aws_cloudwatch_log_stream.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_kms_alias.kinesis_firehose_stream_bucket
  to   = aws_kms_alias.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_kms_key.kinesis_firehose_stream_bucket
  to   = aws_kms_key.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket_acl.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket_acl.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket_lifecycle_configuration.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket_lifecycle_configuration.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket_ownership_controls.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket_ownership_controls.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket_server_side_encryption_configuration.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket_server_side_encryption_configuration.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.aws_s3_bucket_versioning.kinesis_firehose_stream_bucket
  to   = aws_s3_bucket_versioning.legacy_log_cache[0]
}

moved {
  from = module.kinesis-firehose.module.kinesis_firehose_stream_bucket_config.aws_s3_bucket_inventory.daily
  to   = module.legacy_log_cache_bucket_config[0].aws_s3_bucket_inventory.daily
}

moved {
  from = module.kinesis-firehose.module.kinesis_firehose_stream_bucket_config.aws_s3_bucket_public_access_block.public_block
  to   = module.legacy_log_cache_bucket_config[0].aws_s3_bucket_public_access_block.public_block
}
