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

module "git2s3_src" {
  source = "../../modules/cfn_artifacts" 

  git2s3_stack_name    = "CodeSync-IdentityBaseImage"
  external_account_ids = [
    "555546682965",
    "917793222841",
    "034795980528",
  ]
  artifact_bucket      = "login-gov-public-artifacts-us-west-2"
}

module "main" {
  source = "../module"
  depends_on = [module.git2s3_src.output_bucket]
}
