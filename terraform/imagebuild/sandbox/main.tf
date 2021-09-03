provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
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
  source     = "../module"

  code_branch    = var.code_branch
}
