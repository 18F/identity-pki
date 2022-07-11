provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["461353137281"] # require analytics
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env_name = "prod"
}
