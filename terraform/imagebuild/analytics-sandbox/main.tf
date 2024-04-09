provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["487317109730"] # require login-analytics-sandbox
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
  source = "../module_native"

  account_name          = "analytics-sandbox"
  env_name              = "main"
  git2s3_bucket_name    = "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name        = "analytics-sandbox"
  image_build_nat_eip = "34.208.223.88"
}

module "beta" {
  source = "../module_native"

  account_name          = "analytics-sandbox"
  env_name              = "beta"
  git2s3_bucket_name    = "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}
