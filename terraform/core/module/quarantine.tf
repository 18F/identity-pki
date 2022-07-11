# Creates the S3 bucket and KMS Key required for the quarantine bucket 

locals {
  quarantine_s3_bucket_name = "login-gov.quarantine-ec2.${data.aws_caller_identity.current.account_id}-${var.region}"
}


resource "aws_kms_key" "quarantine-ec2" {
  description             = "KMS Key for the quarantine S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "quarantine-ec2" {
  name          = "alias/quarantine-ec2"
  target_key_id = aws_kms_key.quarantine-ec2.key_id
}

resource "aws_s3_bucket" "quarantine-ec2" {
  bucket = local.quarantine_s3_bucket_name
}

resource "aws_s3_bucket_acl" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.quarantine-ec2.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id
  policy = data.aws_iam_policy_document.s3_quarantine-ec2.json
}

resource "aws_s3_bucket_logging" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id

  target_bucket = local.s3_logs_bucket
  target_prefix = "${local.quarantine_s3_bucket_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "quarantine-ec2" {
  bucket = aws_s3_bucket.quarantine-ec2.id

  rule {
    id     = "expire"
    status = "Enabled"
    filter {
      prefix = "/"
    }

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
      noncurrent_days = 2190
    }
  }
}

data "aws_iam_policy_document" "s3_quarantine-ec2" {

  statement {
    sid    = "S3AccessFullAdmin"
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:PutObject*",
      "s3:List*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"]
    }


    resources = [
      "arn:aws:s3:::${local.quarantine_s3_bucket_name}",
      "arn:aws:s3:::${local.quarantine_s3_bucket_name}/*",
    ]
  }
}

