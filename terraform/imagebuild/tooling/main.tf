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

variable "code_branch" {
  default = "main"
}

##### uncomment to test deployments in login-tooling #####
#module "main" {
#  source = "../module"
#
#  trigger_source = "CloudWatch"
#  code_branch    = var.code_branch
#}
