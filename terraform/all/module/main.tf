# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 2.67.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 1.3"
    }
  }
  required_version = ">= 0.13"
}

resource "aws_iam_account_alias" "standard_alias" {
  account_alias = var.iam_account_alias
}

data "aws_caller_identity" "current" {}

# allow assuming of roles from login-master
data "aws_iam_policy_document" "master_account_assumerole" {
  statement {
    sid = "AssumeRoleFromMasterAccount"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.master_account_id}:root"
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

module "tf-state" {
  #source = "github.com/18F/identity-terraform//state_bucket?ref=457f31090209a648df29766805c6f94da8e8c52d"
  source = "../../../../identity-terraform/state_bucket"

  region             = var.region
  bucket_name_prefix = "login-gov"
  sse_algorithm      = "AES256"
}

module "main_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  
  logs_bucket          = module.tf-state.s3_log_bucket
  secrets_bucket_type  = "secrets"
  bucket_name_prefix   = "login-gov"
  region               = var.region
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}
