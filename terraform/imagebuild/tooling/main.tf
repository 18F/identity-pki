provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
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

  code_branch         = var.code_branch
  image_build_nat_eip = "35.89.41.224"
  trigger_source      = "CloudWatch"
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name        = "tooling-sandbox"
  image_build_nat_eip = "35.89.41.202"
}

module "beta" {
  source = "../module_native"

  account_name          = "tooling-sandbox"
  env_name              = "beta"
  git2s3_bucket_name    = "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}
