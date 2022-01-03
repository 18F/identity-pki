provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling
  profile             = "login-tooling"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

locals {
  repos = {
    alpine-internal = {
      prod = "write"
      tooling = "write"
      
    }

    nginx-internal = {
      secondAChoice = "foobar"
      secondBChoice = "barfoo"
    }
  }
}


module "settings" {
  source = "../module-ecr-global-settings"

  env_name                       = "tooling"
  region                         = "us-west-2"
  continuous_scan_filter         = "*"
  scan_on_push_filter            = "*"
}

module "repos" {
  source = "../module-ecr-repo"

  env_name                       = "tooling"
  region                         = "us-west-2"

}
