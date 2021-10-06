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

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "logexpire"
    enabled = true
    prefix  = ""

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

    noncurrent_version_transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 365
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 2190
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
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