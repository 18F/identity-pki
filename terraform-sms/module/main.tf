provider "aws" {
  region = "${var.region}"
  version = "~> 2.6"
}

provider "external" { version = "~> 1.0" }
provider "null"     { version = "~> 1.0" }
provider "template" { version = "~> 1.0" }

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
