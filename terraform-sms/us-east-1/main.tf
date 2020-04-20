# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

provider "external" { version = "~> 1.0" }
provider "null" { version = "~> 2.1.2" }
provider "template" { version = "~> 2.1.2" }

data "aws_caller_identity" "current" {}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 30
  max_password_age               = 365
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}

# Block creation of public S3 buckets, account-wide
resource "aws_s3_account_public_access_block" "acct-policy" {
  block_public_acls   = true
  block_public_policy = true
}

module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=d111d1df1e47671313430b6f1492735ae45767bf"
  region = var.region
}

locals {
  s3_log_bucket = module.tf-state.s3_log_bucket
}

