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

variable "code_branch" {
  default = "main"
}

module "git2s3_src" {
  #source = "../../modules/cfn_artifacts"
  source = "../../../../identity-terraform/git2s3_artifacts"
  #source = "github.com/18F/identity-terraform//git2s3_artifacts?ref=1cfce5da012958febe2f405ead06eac067b0cc5a"

  git2s3_stack_name    = "CodeSync-IdentityBaseImage"
  external_account_ids = [
    "555546682965",
    "917793222841",
    "034795980528",
  ]
  #artifact_bucket      = "login-gov-public-artifacts-us-west-2"
  bucket_name_prefix = "login-gov"
  sse_algorithm      = "AES256"
}

module "main" {
  source     = "../module"
  depends_on = [module.git2s3_src.output_bucket]

  code_branch    = var.code_branch
}
