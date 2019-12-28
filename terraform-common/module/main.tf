# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

provider "external" { version = "~> 1.2" }
provider "null" { version = "~> 2.1.2" }
provider "template" { version = "~> 2.1.2" }

# Module that manages the terraform remote state bucket and creates the S3 logs bucket
module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=d111d1df1e47671313430b6f1492735ae45767bf"
  region = var.region
}

locals {
  s3_log_bucket = module.tf-state.s3_log_bucket
}
