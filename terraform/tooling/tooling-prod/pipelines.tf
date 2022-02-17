# Set up global config for codebuild/pipeline
module "main" {
  source = "../module"
  region = "us-west-2"
  # The domain we put this stuff under
  dns_domain = "gitlab.login.gov"
}

# deploy the prod gitlab environment to the tooling account on the main branch!
module "login-prod" {
  region = "us-west-2"
  source = "../module-pipeline"

  # This is the dir under the terraform dir to tf in identity-devops
  tf_dir = "gitlab/login-prod"
  # This is the gitref to check out in identity-devops
  gitref = "main"
  # this is the environment that we will recycle/test
  recycletest_env_name = "login-prod"
  # this is the dns domain that we need to test
  recycletest_domain = "gitlab.login.gov"
  # This is the account to deploy tf_dir into
  account = "217680906704"

  # pass in global config using module composition (https://www.terraform.io/docs/modules/composition.html)
  auto_tf_vpc_id            = module.main.auto_tf_vpc_id
  auto_tf_subnet_id         = module.main.auto_tf_subnet_id
  auto_tf_subnet_arn        = module.main.auto_tf_subnet_arn
  auto_tf_role_arn          = module.main.auto_tf_role_arn
  auto_tf_sg_id             = module.main.auto_tf_sg_id
  auto_tf_bucket_id         = module.main.auto_tf_bucket_id
  auto_tf_pipeline_role_arn = module.main.auto_tf_pipeline_role_arn
}

# deploy the all/tooling-prod target to the tooling-prod account on the main branch
module "alltoolingprod" {
  region = "us-west-2"
  source = "../module-pipeline"

  # This is the dir under the terraform dir to tf in identity-devops
  tf_dir = "all/tooling-prod"
  # This is the gitref to check out in identity-devops
  gitref = "main"
  # This is the account to deploy tf_dir into
  account = "217680906704"
  # This is needed so that we don't have name collisions
  recycletest_env_name = "alltoolingprod"

  # pass in global config using module composition (https://www.terraform.io/docs/modules/composition.html)
  auto_tf_vpc_id            = module.main.auto_tf_vpc_id
  auto_tf_subnet_id         = module.main.auto_tf_subnet_id
  auto_tf_subnet_arn        = module.main.auto_tf_subnet_arn
  auto_tf_role_arn          = module.main.auto_tf_role_arn
  auto_tf_sg_id             = module.main.auto_tf_sg_id
  auto_tf_bucket_id         = module.main.auto_tf_bucket_id
  auto_tf_pipeline_role_arn = module.main.auto_tf_pipeline_role_arn
}

# deploy the imagebuild/tooling-prod target to the tooling-prod account on the main branch
module "imagebuildtoolingprod" {
  region = "us-west-2"
  source = "../module-pipeline"

  # This is the dir under the terraform dir to tf in identity-devops
  tf_dir = "imagebuild/tooling-prod"
  # This is the gitref to check out in identity-devops
  gitref = "main"
  # This is the account to deploy tf_dir into
  account = "217680906704"
  # This is needed so that we don't have name collisions
  recycletest_env_name = "imagebuildtoolingprod"

  # pass in global config using module composition (https://www.terraform.io/docs/modules/composition.html)
  auto_tf_vpc_id            = module.main.auto_tf_vpc_id
  auto_tf_subnet_id         = module.main.auto_tf_subnet_id
  auto_tf_subnet_arn        = module.main.auto_tf_subnet_arn
  auto_tf_role_arn          = module.main.auto_tf_role_arn
  auto_tf_sg_id             = module.main.auto_tf_sg_id
  auto_tf_bucket_id         = module.main.auto_tf_bucket_id
  auto_tf_pipeline_role_arn = module.main.auto_tf_pipeline_role_arn
}
