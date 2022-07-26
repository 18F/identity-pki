data "aws_caller_identity" "current" {
}

locals {
  inventory_bucket_arn = "arn:aws:s3:::login-gov.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}
resource "aws_kinesis_firehose_delivery_stream" "cloudwatch-exporter" {
  name        = var.kinesis_firehose_stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn       = aws_iam_role.kinesis_firehose_stream_role.arn
    bucket_arn     = aws_s3_bucket.kinesis_firehose_stream_bucket.arn
    buffer_size    = 128
    s3_backup_mode = "Enabled"
    prefix         = "logs/"

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

  depends_on = [
    aws_s3_bucket.kinesis_firehose_stream_bucket
  ]
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
  policy                  = data.aws_iam_policy_document.kinesis_s3_kms.json
}

resource "aws_kms_alias" "kinesis_firehose_stream_bucket" {
  name          = "alias/${var.env_name}-kms-s3-log-cache-bucket"
  target_key_id = aws_kms_key.kinesis_firehose_stream_bucket.key_id
}

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_acl" "kinesis_firehose_stream_bucket" {
  bucket = aws_s3_bucket.kinesis_firehose_stream_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "kinesis_firehose_stream_bucket" {
  bucket = aws_s3_bucket.kinesis_firehose_stream_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kinesis_firehose_stream_bucket" {
  bucket = aws_s3_bucket.kinesis_firehose_stream_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kinesis_firehose_stream_bucket.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "kinesis_firehose_stream_bucket" {
  bucket = aws_s3_bucket.kinesis_firehose_stream_bucket.id

  rule {
    id     = "expire_files"
    status = "Enabled"
    filter {
      prefix = ""
    }

    expiration {
      days = var.expiration_days
    }
  }
}

module "kinesis_firehose_stream_bucket_config" {
  source               = "github.com/18F/identity-terraform//s3_config?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  depends_on           = [aws_s3_bucket.kinesis_firehose_stream_bucket]
  bucket_name_override = aws_s3_bucket.kinesis_firehose_stream_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

# HACK: use null_resource to make cloudwatch_subscription_filter wait
# to be created until stream is in ACTIVE state
# see: https://github.com/hashicorp/terraform-provider-aws/issues/17049

resource "null_resource" "kinesis_firehose_stream_active" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]

    environment = {
      STREAM = ""
    }

    command = <<EOC
while [[ "$STREAM" != "ACTIVE" ]] ; do
  STREAM=$(aws firehose describe-delivery-stream \
            --delivery-stream-name ${var.kinesis_firehose_stream_name} \
            --query 'DeliveryStreamDescription.DeliveryStreamStatus' \
            --output text)
  sleep 5
done
EOC
  }
  triggers = {
    cloudwatch_exporter_arn = aws_kinesis_firehose_delivery_stream.cloudwatch-exporter.arn
  }
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  count          = length(var.cloudwatch_log_group_name)
  name           = var.cloudwatch_subscription_filter_name
  log_group_name = var.cloudwatch_log_group_name[count.index]
  filter_pattern = var.cloudwatch_filter_pattern

  destination_arn = aws_kinesis_firehose_delivery_stream.cloudwatch-exporter.arn
  distribution    = "ByLogStream"

  role_arn = aws_iam_role.cloudwatch_logs_role.arn

  depends_on = [
    null_resource.kinesis_firehose_stream_active,
    aws_kinesis_firehose_delivery_stream.cloudwatch-exporter,
    aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group,
    aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream,
  ]
}