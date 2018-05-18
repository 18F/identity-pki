provider "aws" {
  region = "${var.region}"
  version = "~> 1.18"
}

provider "external" { version = "~> 1.0" }
provider "null"     { version = "~> 1.0" }
provider "template" { version = "~> 1.0" }

# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}
