# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

provider "external" { version = "~> 1.2" }
provider "null" { version = "~> 2.1.2" }
provider "template" { version = "~> 2.1.2" }

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}
