terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.71.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.0"
    }
    github = {
      source  = "integrations/github"
      version = "4.19.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "2.35.0"
    }
  }
  required_version = ">= 1.1.3"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "usw2"
  region = var.region
}
