provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-alpha
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "code_branch" {
  default = "main"
}

#### uncomment to test deployments in login-alpha #####
module "main" {
  source = "../module"

  trigger_source      = "CloudWatch"
  code_branch         = var.code_branch
  image_build_nat_eip = "54.70.214.142"
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name        = "alpha"
  image_build_nat_eip = "44.232.112.91"
}

module "alpha" {
  source = "../module_native"

  account_name          = "alpha"
  env_name              = "alpha"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}