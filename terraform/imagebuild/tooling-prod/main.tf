provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
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
  image_build_nat_eip = "35.89.44.224" # TODO: make this programmable
}
