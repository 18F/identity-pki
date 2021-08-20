terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
  }
  required_version = ">= 1.0.2"
}

data "aws_caller_identity" "current" {
}

resource "aws_s3_account_public_access_block" "s3_limits" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
