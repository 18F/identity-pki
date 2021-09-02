data "aws_caller_identity" "current" {
}

module "git2s3_src" {
  count = data.aws_caller_identity.current.account_id == "894947205914" ? 1 : 0
  #source = "../../../../identity-terraform/git2s3_artifacts"
  source = "github.com/18F/identity-terraform//git2s3_artifacts?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  providers = {
    aws = aws.usw2
  }

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
