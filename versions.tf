# If you are updating plugins in here, be sure to transfer the old versions
# over to the versions.tf.old file, so that it won't break people who are
# running auto-tf on branches that don't have your latest/greatest stuff.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.21.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.2"
    }
    github = {
      source  = "integrations/github"
      version = "4.26.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "2.48.1"
    }
  }
  required_version = "1.2.4"
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "usw2"
  region = var.region
}
