# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.11.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 1.3"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  region = "us-west-2"
  alias  = "usw2"
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
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

# used for assuming of AutoTerraform role from tooling
data "aws_iam_policy_document" "autotf_assumerole" {
  statement {
    sid = "AssumeTerraformRoleFromAutotfRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.tooling_account_id}:role/auto_terraform"
      ]
    }
  }
}

module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=eb59e91f104f452620eef752fe632f35863d881c"
  #source = "../../../../identity-terraform/state_bucket"

  remote_state_enabled = 0
  region             = var.region
  bucket_name_prefix = "login-gov"
  sse_algorithm      = "AES256"
}

module "main_secrets_bucket" {
  source              = "../../modules/secrets_bucket"
  depends_on = [module.tf-state.s3_log_bucket]
  
  logs_bucket          = module.tf-state.s3_log_bucket
  secrets_bucket_type  = "secrets"
  bucket_name_prefix   = "login-gov"
  region               = var.region
}

output "main_secrets_bucket" {
  value = module.main_secrets_bucket.bucket_name
}
