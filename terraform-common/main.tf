provider "aws" {
  region  = var.region
  version = "~> 2.37.0"
}

provider "external" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1.2"
}

provider "template" {
  version = "~> 2.1.2"
}

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}

