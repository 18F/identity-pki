terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
  }
}

data "aws_caller_identity" "current" {}
