data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "shared" {
  statement {
    principals {
      type        = "AWS"
      identifiers = var.power_users
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = var.power_users
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov-shared-data-${data.aws_caller_identity.current.account_id}/*",
    ]
  }
}

resource "aws_s3_bucket" "shared" {
  bucket        = "login-gov-shared-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  policy        = data.aws_iam_policy_document.shared.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# Create a common bucket for storing ELB/ALB access logs
# The bucket name will be like this:
#   login-gov.elb-logs.<ACCOUNT_ID>-<AWS_REGION>
module "elb-logs" {
  # can't use variable for ref -- see https://github.com/hashicorp/terraform/issues/17994
  source = "github.com/18F/identity-terraform//elb_access_logs_bucket?ref=f6f34ddcad06b29b87d2d8cc8fddd9d49ec23b61"

  region                     = var.region
  bucket_name_prefix         = "login-gov"
  use_prefix_for_permissions = false

  lifecycle_days_standard_ia = 60   # 2 months
  lifecycle_days_glacier     = 365  # 1 year
  lifecycle_days_expire      = 2190 # 6 years
}

output "elb_log_bucket" {
  value = module.elb-logs.bucket_name
}

# Bucket used for storing S3 access logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expirelogs"
    enabled = true

    prefix = "/"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
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

# policy allowing SES to upload files to the email bucket under /inbound/*
data "aws_iam_policy_document" "ses-upload" {
  statement {
    sid    = "AllowSESPuts"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov.email.${data.aws_caller_identity.current.account_id}-${var.region}/inbound/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:Referer"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Bucket used for storing email stuff, such as inbound email
resource "aws_s3_bucket" "s3-email" {
  bucket = "login-gov.email.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region

  policy = data.aws_iam_policy_document.ses-upload.json

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
    target_prefix = "login-gov.email.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  lifecycle_rule {
    id      = "expireinbound"
    enabled = true

    prefix = "/inbound/"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # delete after 1 year
    expiration {
      days = 365
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

# Bucket used for storing lambda code deployment bundles
resource "aws_s3_bucket" "lambda-functions" {
  bucket = "login-gov.lambda-functions.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region

  policy = data.aws_iam_policy_document.lambda-functions.json

  # Move to IA after 180 days
  lifecycle_rule {
    id      = "inactive"
    enabled = true

    prefix = "/"

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# Policy covering uploads to the lambda functions bucket
data "aws_iam_policy_document" "lambda-functions" {
  # Allow CircleCI role to upload under /circleci/*
  statement {
    sid    = "AllowCircleCIPuts"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.circleci.arn]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov.lambda-functions.${data.aws_caller_identity.current.account_id}-${var.region}/circleci/*",
    ]
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
  count  = var.manage_state_bucket ? 1 : 0
  bucket = "login-gov.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region
  acl    = "private"
  policy = ""
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
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
  bucket = aws_s3_bucket.tf-state[0].id

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
#     ./deploy global <USER> terraform-common import aws_dynamodb_table.tf-lock-table terraform_locks
#
# Under the hood this is running:
#
#     terraform import aws_dynamodb_table.tf-lock-table terraform_locks
#
resource "aws_dynamodb_table" "tf-lock-table" {
  count          = var.manage_state_bucket ? 1 : 0
  name           = var.state_lock_table
  read_capacity  = 2
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # TODO newer AWS provider only
  #server_side_encryption {
  #  enabled = true
  #}

  lifecycle {
    prevent_destroy = true
  }
}

# Bucket used for storing generated reports
resource "aws_s3_bucket" "reports" {
  bucket = "login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}"
  region = var.region

  acl    = "private"
  policy = ""

  logging {
    target_bucket = aws_s3_bucket.s3-logs.id
    target_prefix = "login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/"
  }

  lifecycle_rule {
    id      = "aging"
    enabled = true

    prefix = "/"

    # move to infrequent access after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    # keep forever
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# Block public access to reports. We may revisit in the future if we do want to expose some subset of reports.
resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "s3_log_bucket" {
  value = aws_s3_bucket.s3-logs.id
}

