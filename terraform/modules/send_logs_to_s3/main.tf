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
  acl    = "private"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire_files"
    enabled = true
    prefix  = ""

    expiration {
      days = var.expiration_days
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kinesis_firehose_stream_bucket.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

}

module "kinesis_firehose_stream_bucket_config" {
  source               = "github.com/18F/identity-terraform//s3_config?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  depends_on           = [aws_s3_bucket.kinesis_firehose_stream_bucket]
  bucket_name_override = aws_s3_bucket.kinesis_firehose_stream_bucket.id
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}

###### HACK #######
# Even with depends_on, Terraform will attempt to create cloudwatch_subscription_filter
# when the cloudwatch-exporter stream is in the CREATING status, and will fail
# as the stream is unable to accept data unless it is in ACTIVE status.
# This uses null_resource to wait for the DeliveryStreamStatus to equal ACTIVE,
# and THEN create the cloudwatch_subscription_filter below.
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