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

module "tooling-sandbox" {
  source = "../module_native"

  base_codebuild_name  = "login-image-base"
  rails_codebuild_name = "login-image-rails"
  base_pipeline_name   = "CodePipeline-ImageBaseRole-CodePipeline-1DU4NVSG4OZIU"
  rails_pipeline_name  = "CodePipeline-ImageRailsRole-CodePipeline-STV0QQNWHM27"

  account_name          = "tooling-sandbox"
  env_name              = "tooling-sandbox"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}

module "beta" {
  source = "../module_native"

  account_name          = "tooling-sandbox"
  env_name              = "beta"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}
