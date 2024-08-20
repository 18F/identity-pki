locals {
  region     = "us-west-2"
  account_id = "555546682965"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-prod
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
  image_build_nat_eip = "34.216.215.32"

  ami_regions = ["us-west-2"] # until approved in SIA/SCR for us-east-1 infra
}

module "vpc" {
  source = "../../modules/utility_vpc"

  account_name              = "prod"
  image_build_nat_eip       = "34.216.215.127"
  cloudwatch_retention_days = 3653
}

module "prod" {
  source = "../module_native"

  ami_copy_region      = "" # until approved in SIA/SCR for us-east-1 infra
  base_codebuild_name  = "login-image-base"
  rails_codebuild_name = "login-image-rails"
  base_pipeline_name   = "CodePipeline-ImageBaseRole-CodePipeline-FQCFK54PTLA0"
  rails_pipeline_name  = "CodePipeline-ImageRailsRole-CodePipeline-179TVA5T5VYTP"

  account_name          = "prod"
  build_alarms_enable   = true
  env_name              = "prod"
  identity_base_git_ref = "main"
  private_subnet_id     = module.vpc.private_subnet_id
  vpc_id                = module.vpc.vpc_id
}
