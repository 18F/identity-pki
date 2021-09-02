terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
  }
  required_version = ">= 0.13.7"
}

data "aws_caller_identity" "current" {}
