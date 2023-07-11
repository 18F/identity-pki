resource "aws_s3_bucket" "email" {
  bucket = "${local.bucket_name_prefix}.email.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket_ownership_controls" "email" {
  bucket = aws_s3_bucket.email.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "email" {
  bucket = aws_s3_bucket.email.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.email]
}

# Policy allowing SES to upload files to the email bucket under /inbound/*
# and automation accounts to fetch from it 
resource "aws_s3_bucket_policy" "email" {
  bucket = aws_s3_bucket.email.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSESPuts",
      "Effect": "Allow",
      "Principal": {
        "Service": "ses.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.email.id}/inbound/*",
      "Condition": {
        "StringEquals": {
          "aws:Referer": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
POLICY
}

# Use AES256 - Nothing sensitive should land here and it sidesteps the
# need to give SES access to the KMS key used for the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "email" {
  bucket = aws_s3_bucket.email.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "email" {
  bucket = aws_s3_bucket.email.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "email" {
  bucket = aws_s3_bucket.email.id

  target_bucket = local.s3_logs_bucket_uw2
  target_prefix = "${aws_s3_bucket.email.id}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "email" {
  bucket = aws_s3_bucket.email.id

  rule {
    id     = "expireinbound"
    status = "Enabled"

    filter {
      prefix = "/inbound/"
    }

    expiration {
      days = 90
    }
  }
}

module "s3_email_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/s3_config"

  bucket_name_prefix   = local.bucket_name_prefix
  bucket_name          = "email"
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
  block_public_access  = true
}
