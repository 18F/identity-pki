# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27.0"
    }
    github = {
      source = "hashicorp/github"
      version = "~> 2.9"
    }
  }
  required_version = ">= 0.13"
}

data "aws_caller_identity" "current" {}

data "github_ip_ranges" "ips" {}

data "aws_availability_zones" "available" {}
