# TODO: move all of this into a module

# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = "${var.region}"
  acl = "log-delivery-write"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id = "expirelogs"
    enabled = true

    prefix  = "/"

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 365
      storage_class = "GLACIER"
    }

    expiration {
      # 5 years
      days = 1825
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# This is the terraform state bucket used by terraform including by this
# terraform file itself. Obviously this is a circular dependency, so there is a
# major chicken/egg bootstrapping problem.
#
# However, it's very important to ensure that the state bucket itself is
# configured with the right settings, so it's worth the pain of managing it.
#
# The bin/configure_state_bucket.sh script should create this bucket
# automatically as part of running ./deploy, but you can also create the bucket
# manually.
#
# Then import the existing bucket into the terraform-common terraform state using the deploy wrapper:
#
#     ./deploy global <USER> terraform-common import aws_s3_bucket.tf-state login-gov.tf-state.<ACCT_ID>-<REGION>
#
# Under the hood this is running:
#
#     terraform import aws_s3_bucket.tf-state login-gov.tf-state.<ACCT_ID>-<REGION>
#
resource "aws_s3_bucket" "tf-state" {
  count = "${var.manage_state_bucket ? 1 : 0}"
  bucket = "login-gov.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = "${var.region}"
  acl = "private"
  policy = ""
  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.s3-logs.id}"
    target_prefix = "login-gov.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_public_access_block" "tf-state" {
    bucket = "${aws_s3_bucket.tf-state.id}"

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# This is the terraform state lock file used by terraform including by this
# terraform file itself. Obviously this is a circular dependency like the AWS
# S3 bucket, so there is a major chicken/egg bootstrapping problem.
#
# The bin/configure_state_bucket.sh script should create this table
# automatically as part of running ./deploy, but you can also create this table
# manually.
#
# Then import the existing table into the terraform-common terraform state
# using the deploy wrapper (with terraform_locks as the table name in this
# example):
#
#     ./deploy <env> terraform-sms import module.main.aws_dynamodb_table.tf-lock-table terraform_locks
#
# Under the hood this is running:
#
#     terraform import module.main.aws_dynamodb_table.tf-lock-table terraform_locks
#
resource "aws_dynamodb_table" "tf-lock-table" {
  count          = "${var.manage_state_bucket ? 1 : 0}"
  name           = "${var.state_lock_table}"
  read_capacity  = 2
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "s3_log_bucket" {
  value = "${aws_s3_bucket.s3-logs.id}"
}
