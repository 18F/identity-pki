terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.52.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.13.0"
    }
  }
  required_version = ">= 0.13.7"
}
