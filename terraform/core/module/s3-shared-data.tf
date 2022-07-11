data "aws_caller_identity" "current" {
}

resource "aws_s3_bucket" "shared_data" {
  bucket        = "${local.bucket_name_prefix}.shared-data.${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdministrator"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.shared_data.id}"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdministrator"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.shared_data.id}/*"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_server_side_encryption_configuration" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  target_bucket = local.s3_logs_bucket
  target_prefix = "${aws_s3_bucket.shared_data.id}/"
}

module "s3_shared_data_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=5d338480d96af4c5123fcbebb0d0a189e31496b4"

  bucket_name_prefix   = local.bucket_name_prefix
  bucket_name          = "shared_data"
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_uw2_arn
  block_public_access  = true
}
