provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
  profile             = "login.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "code_branch" {
  default = "main"
}

module "main" {
  source = "../module"

  trigger_source      = "CloudWatch"
  code_branch         = var.code_branch
  image_build_nat_eip = "34.216.215.32" # TODO: make this programmable
}
