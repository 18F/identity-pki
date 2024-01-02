provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["221972985980"] # require login-logarchive-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  source_account_id = "894947205914" # login-sandbox
  #secondary_region = "us-east-1" # disable for now
}
