provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["461353137281"] # require analytics
  profile             = "analytics"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env_name                 = "staging"
#  redshift_master_password = var.redshift_master_password
  analytics_version        = "cacraig-06282018-staging-setup-5"
  cloudwatch_5min_enabled = false
}
