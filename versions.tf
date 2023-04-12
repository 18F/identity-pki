# If you are updating plugins in here, be sure to transfer the old versions
# over to the versions.tf.old file, so that it won't break people who are
# running auto-tf on branches that don't have your latest/greatest stuff.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.62.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.1"
    }
    github = {
      source  = "integrations/github"
      version = "5.18.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = "1.3.5"
}

provider "aws" {
  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }
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
