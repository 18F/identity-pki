resource "aws_s3_bucket" "email" {
  bucket = "${local.bucket_name_prefix}.email.${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket_acl" "email" {
  bucket = aws_s3_bucket.email.id
  acl    = "private"
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
    },
    {
      "Sid": "AllowEmailList",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::894947205914:user/circle-ci-test-coverage"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.email.id}"
    },
    {
      "Sid": "AllowEmailDownload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::894947205914:user/circle-ci-test-coverage"
      },
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.email.id}/inbound/*"
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

  target_bucket = local.s3_logs_bucket
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
  source = "github.com/18F/identity-terraform//s3_config?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  bucket_name_prefix   = local.bucket_name_prefix
  bucket_name          = "email"
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
  block_public_access  = true
}
