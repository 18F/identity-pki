terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 2.67.0"
    }
  }
  required_version = ">= 0.13"
}

locals {
  password_length = 32
}

data "aws_caller_identity" "current" {
}

module "iam_account" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-account"
  version       = "~> 2.21.0"
  account_alias = "login-master"

  allow_users_to_change_password = true
  create_account_password_policy = true
  max_password_age               = 90
  minimum_password_length        = local.password_length
  password_reuse_prevention      = 1
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
}

resource "aws_s3_account_public_access_block" "s3_limits" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
