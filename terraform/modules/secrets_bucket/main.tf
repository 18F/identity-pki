data "aws_caller_identity" "current" {
}

locals {
  bucket_name = "${var.bucket_name_prefix}.${var.secrets_bucket_type}.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "secrets" {
  bucket        = local.bucket_name
  acl           = "private"
  force_destroy = var.force_destroy

  policy = ""

  tags = {
    Name        = var.bucket_name_prefix
    Environment = "All"
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.logs_bucket
    target_prefix = "${local.bucket_name}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secrets" {
  bucket = aws_s3_bucket.secrets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# add default Slack keys
resource "aws_s3_bucket_object" "slack_channel" {
  bucket = aws_s3_bucket.secrets.id
  key    = "slackchannel"
  content = var.slack_channel
}

resource "aws_s3_bucket_object" "slack_webhook" {
  bucket = aws_s3_bucket.secrets.id
  key    = "slackwebhook"
  content = var.slack_webhook
}
