locals {
  #stream name must start with "aws-waf-logs"
  kinesis_firehose_name   = "aws-waf-logs-${var.env}-idp"
  s3_inventory_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::login-gov.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "waf_logs" {
  bucket = "login-gov.${local.web_acl_name}-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  acl    = "private"

  logging {
    target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "login-gov.${local.web_acl_name}-logs.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  tags = {
    environment = var.env
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire"
    prefix  = "/"
    enabled = true

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
      days = 2190
    }
  }
}

module "waf_log_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=91eadab865ca59a2998387681ca83ac401b7c352"

  bucket_name_override = aws_s3_bucket.waf_logs.id
  inventory_bucket_arn = local.s3_inventory_bucket_arn
}

resource "aws_cloudwatch_log_group" "kinesis_waf_logs" {
  name              = "/aws/kinesisfirehose/${local.web_acl_name}-logs"
  retention_in_days = 365
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = local.kinesis_firehose_name
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.waf_logs.arn
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${local.kinesis_firehose_name}"
      log_stream_name = "s3delivery"
    }
    buffer_size        = 50
    buffer_interval    = 300
    compression_format = "GZIP"
  }
}

resource "aws_iam_role" "firehose" {
  name = "${local.web_acl_name}-logs-firehose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "firehose_role_policy" {
  name   = "${var.env}_firehose_waf_role_policy"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.firehose_policy.json
}

data "aws_iam_policy_document" "firehose_policy" {
  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:Get*",
      "s3:List*",
      "s3:Put*"
    ]
    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*"
    ]
  }
}
