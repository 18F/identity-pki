provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
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
  image_build_nat_eip = "34.216.215.164"
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name        = "sandbox"
  image_build_nat_eip = "34.216.215.191"
}

module "sandbox" {
  source = "../module_native"

  base_codebuild_name  = "login-image-base"
  rails_codebuild_name = "login-image-rails"
  base_pipeline_name   = "CodePipeline-ImageBaseRole-CodePipeline-P8D1D3UMYIYC"
  rails_pipeline_name  = "CodePipeline-ImageRailsRole-CodePipeline-1KO0M68848JXH"

  account_name          = "sandbox"
  build_alarms_enable   = true
  env_name              = "sandbox"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}

module "beta" {
  source = "../module_native"

  account_name          = "sandbox"
  env_name              = "beta"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}

