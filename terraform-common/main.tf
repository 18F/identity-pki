provider "aws" {
  region = "${var.region}"
  version = "~> 2.6"
}

provider "external" { version = "~> 1.0" }
provider "null"     { version = "~> 1.0" }
provider "template" { version = "~> 1.0" }

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}
