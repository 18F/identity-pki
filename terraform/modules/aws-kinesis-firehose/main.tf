resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_stream" {
  name        = var.kinesis_firehose_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn       = aws_iam_role.kinesis_firehose_stream_role.arn
    bucket_arn     = aws_s3_bucket.kinesis_firehose_stream_bucket.arn
    buffer_size    = 128
    s3_backup_mode = "Enabled"
    prefix         = "logs/"
    compression_format = "UNCOMPRESSED"

    s3_backup_configuration {
      role_arn   = aws_iam_role.kinesis_firehose_stream_role.arn
      bucket_arn = aws_s3_bucket.kinesis_firehose_stream_bucket.arn
      prefix     = var.kinesis_firehose_stream_backup_prefix

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
        log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name
    }
  }
}

resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group" {
  name = "/aws/kinesisfirehose/${var.kinesis_firehose_stream_name}"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream" {
  log_group_name = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
  name           = "S3Delivery"
}

resource "aws_kms_key" "kinesis_firehose_stream_bucket" {
  description             = "KMS key for ${var.bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire_files_in_90_days"
    enabled = true
    prefix  = ""

    expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kinesis_firehose_stream_bucket.arn
        sse_algorithm = "aws:kms"
      }
    }
  }

}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  count          = length(var.cloudwatch_log_group_name)
  name           = var.cloudwatch_subscription_filter_name
  log_group_name = var.cloudwatch_log_group_name[count.index]
  filter_pattern = var.cloudwatch_filter_pattern

  destination_arn = aws_kinesis_firehose_delivery_stream.kinesis_firehose_stream.arn
  distribution    = "ByLogStream"

  role_arn = aws_iam_role.cloudwatch_logs_role.arn
}