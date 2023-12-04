# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  code_branch         = var.code_branch
  image_build_nat_eip = "34.216.215.164" # TODO: make this programmable
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name        = "sandbox"
  image_build_nat_eip = "54.184.227.90"
}

module "beta" {
  source = "../module_native"

  account_name          = "sandbox"
  env_name              = "beta"
  git2s3_bucket_name    = "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"
  identity_base_git_ref = "ryandbrown/pipeline_fixes"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}

variable "code_branch" {
  default = "main"
}

variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}
