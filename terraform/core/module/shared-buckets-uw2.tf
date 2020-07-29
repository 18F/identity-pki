data "aws_caller_identity" "current" {
}

locals {
  s3_buckets_uw2 = {
    "shared-data" = {},
    "email" = {
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
    },
    "waf-logs"     = {},
  }
}

module "s3_shared_uw2" {
  source = "github.com/18F/identity-terraform//s3_bucket_block?ref=5936d2aa33f5835bf7576e74061185cae61da4d9"
  #source = "../../../../identity-terraform/s3_bucket_block"
  
  bucket_prefix = "login-gov"
  bucket_data = local.s3_buckets_uw2
}

# Policy for shared-data bucket
resource "aws_s3_bucket_policy" "shared" {
  bucket = module.s3_shared_uw2.buckets["shared-data"]
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
      "Resource": "arn:aws:s3:::${module.s3_shared_uw2.buckets["shared-data"]}"
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
      "Resource": "arn:aws:s3:::${module.s3_shared_uw2.buckets["shared-data"]}/*"
    }
  ]
}
POLICY
}

# Policy covering uploads to the lambda functions bucket
module "s3_policies_uw2" {
  source = "../../modules/shared_bucket_policies"
  
  lambda_bucket = module.s3_shared_uw2.buckets["lambda-functions"]
  circleci_arn = aws_iam_user.circleci.arn
}

# policy allowing SES to upload files to the email bucket under /inbound/*
resource "aws_s3_bucket_policy" "ses-upload" {
  bucket = module.s3_shared_uw2.buckets["email"]
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
      "Resource": "arn:aws:s3:::${module.s3_shared_uw2.buckets["email"]}/inbound/*",
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

# Policy for shared-data bucket
resource "aws_s3_bucket_policy" "shared" {
  bucket = module.s3_shared.buckets["shared-data"]
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
      "Resource": "arn:aws:s3:::${module.s3_shared.buckets["shared-data"]}"
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
      "Resource": "arn:aws:s3:::${module.s3_shared.buckets["shared-data"]}/*"
    }
  ]
}
POLICY
}

# Policy covering uploads to the lambda functions bucket
resource "aws_s3_bucket_policy" "lambda-functions" {
  bucket = module.s3_shared.buckets["lambda-functions"]
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCircleCIPuts",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.circleci.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${module.s3_shared.buckets["lambda-functions"]}/circleci/*"
    }
  ]
}
POLICY
}

# policy allowing SES to upload files to the email bucket under /inbound/*
resource "aws_s3_bucket_policy" "ses-upload" {
  bucket = module.s3_shared.buckets["email"]
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
      "Resource": "arn:aws:s3:::${module.s3_shared.buckets["email"]}/inbound/*",
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
