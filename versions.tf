# If you are updating plugins in here, be sure to transfer the old versions
# over to the versions.tf.old file, so that it won't break people who are
# running auto-tf on branches that don't have your latest/greatest stuff.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.4"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.3"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "3.39.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
  required_version = "1.8.2"
}

provider "aws" {
  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }

  ignore_tags {
    key_prefixes = ["aws", "AWS"]
  }

  region = var.region
}

provider "aws" {
  alias = "dr"

  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }

  ignore_tags {
    key_prefixes = ["aws", "AWS"]
  }

  region = var.dr_region
}

provider "aws" {
  alias = "use1"

  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }

  ignore_tags {
    key_prefixes = ["aws", "AWS"]
  }

  region = "us-east-1"
}

provider "aws" {
  alias = "usw2"

  default_tags {
    tags = var.fisma_tag == "" ? {} : {
      fisma = var.fisma_tag
    }
  }

  ignore_tags {
    key_prefixes = ["aws", "AWS"]
  }

  region = var.region
}
