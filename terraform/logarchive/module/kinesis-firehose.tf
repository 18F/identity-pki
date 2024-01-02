resource "aws_cloudwatch_log_group" "logarchive_firehose" {
  name = "/aws/kinesisfirehose/${local.aws_alias}-${data.aws_region.current.name}"
}

resource "aws_cloudwatch_log_stream" "logarchive_firehose" {
  log_group_name = aws_cloudwatch_log_group.logarchive_firehose.name
  name           = "FirehoseS3Delivery"
}

resource "aws_kinesis_firehose_delivery_stream" "logarchive" {
  name        = "${local.aws_alias}-${data.aws_region.current.name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.logarchive_firehose.arn
    bucket_arn         = module.logarchive_bucket_primary.bucket_arn
    buffering_size     = 32
    buffering_interval = 60
    s3_backup_mode     = "Enabled"
    prefix             = "firehose/"

    s3_backup_configuration {
      role_arn   = aws_iam_role.logarchive_firehose.arn
      bucket_arn = module.logarchive_bucket_primary.bucket_arn
      prefix     = "backup/"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.logarchive_firehose.name
        log_stream_name = aws_cloudwatch_log_stream.logarchive_firehose.name
      }
    }
  }
}
