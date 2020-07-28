data "aws_caller_identity" "current" {
}

# Policy for shared-data bucket
data "aws_iam_policy_document" "shared" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdministrator"]
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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdministrator"]
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

locals {
  s3_bucket_data = {
    "shared-data" = {
      policy = data.aws_iam_policy_document.shared.json
    },
    "email" = {
      policy          = data.aws_iam_policy_document.ses-upload.json
      lifecycle_rules = [
        {
          id              = "expireinbound"
          enabled         = true
          prefix          = "/inbound/"
          transitions     = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            }
          ]
          expiration_days = 365
        }
      ],
      force_destroy = false
    },
    "lambda-functions" = {
      policy             = data.aws_iam_policy_document.lambda-functions.json
      lifecycle_rules    = [
        {
          id          = "inactive"
          enabled     = true
          prefix      = "/"
          transitions = [
            {
              days          = 180
              storage_class = "STANDARD_IA"
            }
          ]
        }
      ],
      force_destroy = false
    },
    "tf-state"          = {
      force_destroy       = false
      public_access_block = true
    },
    "reports" = {
      lifecycle_rules = [
        {
          id          = "aging"
          enabled     = true
          prefix      = "/"
          transitions = [
            {
              days          = 30
              storage_class = "STANDARD_IA"
            }
          ]
        }
      ],
      force_destroy       = false
      public_access_block = true
    },
    "waf-logs"     = {
    },
  }
}

module "s3_shared" {
  #source = "github.com/18F/identity-terraform//s3_bucket_block?ref=2dcb55a8699a6330aca14f3aa43b53729decd8cf"
  source = "../../../../identity-terraform/s3_bucket_block"
  
  bucket_prefix = "login-gov"
  bucket_data = local.s3_bucket_data
}

# Create a common bucket for storing ELB/ALB access logs
# The bucket name will be like this:
#   login-gov.elb-logs.<ACCOUNT_ID>-<AWS_REGION>
module "elb-logs" {
  # can't use variable for ref -- see https://github.com/hashicorp/terraform/issues/17994
  source = "github.com/18F/identity-terraform//elb_access_logs_bucket?ref=cafa07ecec6afd11d98765b288572462371ed741"

  region                     = var.region
  bucket_name_prefix         = "login-gov"
  use_prefix_for_permissions = false

  lifecycle_days_standard_ia = 60   # 2 months
  lifecycle_days_glacier     = 365  # 1 year
  lifecycle_days_expire      = 2190 # 6 years
}

resource "aws_s3_account_public_access_block" "public_access_block" {
  count = (var.allow_public_buckets ? 1 : 0)

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_iam_user" "circleci" {
  name = "bot=circleci"
  path = "/system/"
}

# This is the terraform state lock file used by terraform including by this
# terraform file itself. Obviously this is a circular dependency like the AWS
# S3 bucket, so there is a major chicken/egg bootstrapping problem.
#
# The bin/configure_state_bucket.sh script should create this table
# automatically as part of running bin/tf-deploy, but you can also create this table
# manually.
#
# Then import the existing table into the core terraform state
# using the deploy wrapper (with terraform_locks as the table name in this
# example):
#
#     bin/tf-deploy core/<ACCOUNT> import aws_dynamodb_table.tf-lock-table terraform_locks
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

output "elb_log_bucket" {
  value = module.elb-logs.bucket_name
}
