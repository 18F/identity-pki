terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.1.2"
    }
  }
  required_version = ">= 1.0.2"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

locals {
  bucket_name_prefix = "login-gov"
  app_secrets_bucket_type = "app-secrets"
  cert_secrets_bucket_type = "internal-certs"
}