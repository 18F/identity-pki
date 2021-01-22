provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling
  profile             = "login-tooling"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

# Set up global config for codebuild/pipeline
module "main" {
  source = "../module"
  region = "us-west-2"
}

# deploy the master/global target to the login-master account
module "masterglobal" {
  region = "us-west-2"
  source = "../module-pipeline"

  # This is the dir under the terraform dir to tf in identity-devops
  tf_dir = "master/global"
  # This is the gitref to check out in identity-devops
  gitref = "master"
  # This is the account to deploy tf_dir into
  account = "login-master"

  # pass in global config using module composition (https://www.terraform.io/docs/modules/composition.html)
  auto_tf_vpc_id = module.main.auto_tf_vpc_id
  auto_tf_subnet_id = module.main.auto_tf_subnet_id
  auto_tf_role_arn = module.main.auto_tf_role_arn
  auto_tf_sg_id = module.main.auto_tf_sg_id
  auto_tf_bucket_id = module.main.auto_tf_bucket_id
  auto_tf_pipeline_role_arn = module.main.auto_tf_pipeline_role_arn
}
