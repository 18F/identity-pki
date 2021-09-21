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

variable "opsgenie_key_ready" {
  default = true
}

module "main" {
  source = "../module"

  opsgenie_key_ready = var.opsgenie_key_ready
  iam_account_alias  = "login-tooling"
  account_roles_map = {
    iam_appdev_enabled = false
  }
  smtp_user_ready = true
}
