# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.11.0"
    }
  }
  required_version = ">= 0.13"
}

data "aws_caller_identity" "current" {}
