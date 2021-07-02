# Creates the S3 buckets and KMS CMK required for quarantine bucket for ec2 instances 
# that have been compromised. 

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
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.quarantine-ec2.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
  
  policy = data.aws_iam_policy_document.s3_quarantine-ec2.json
  
  logging {
    target_bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    target_prefix = "${local.quarantine_s3_bucket_name}/"
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


data "aws_iam_policy_document" "s3_quarantine-ec2" {
  
  statement {
    sid = "Denys3AccessExceptFullAdmin"
    effect = "Deny"

    actions = [
    "s3:*"
    ]

    resources = [
    "arn:aws:s3:::${local.quarantine_s3_bucket_name}",
    "arn:aws:s3:::${local.quarantine_s3_bucket_name}/*",
    ]

    condition {
    test = "StringNotLike"
    variable = "aws:PrincipalArn"
    values = [
    "arn:aws:iam::*:role/FullAdministrator"]
    }
  
    condition {
    test = "StringEquals"
    variable = "s3:x-amz-server-side-encryption"
    values = [
        "aws:kms"
      ]
    }
  }
}
  
