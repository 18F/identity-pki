terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
  }
  required_version = ">= 1.0.2"
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}
