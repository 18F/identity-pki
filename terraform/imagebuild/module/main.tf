data "aws_caller_identity" "current" {}

locals {
  secrets_bucket = join(".", [
    "login-gov", "secrets",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

module "git2s3_src" {
  count = data.aws_caller_identity.current.account_id == "894947205914" ? 1 : 0
  #source = "../../../../identity-terraform/git2s3_artifacts"
  source = "github.com/18F/identity-terraform//git2s3_artifacts?ref=0e5e7c62b940abc34b9661e1af8cbfda8f3f359e"
  providers = {
    aws = aws.usw2
  }

  git2s3_stack_name = "CodeSync-IdentityBaseImage"
  external_account_ids = [
    "555546682965",
    "917793222841",
    "034795980528",
    "217680906704",
  ]
  #artifact_bucket      = "login-gov-public-artifacts-us-west-2"
  bucket_name_prefix = "login-gov"
  sse_algorithm      = "AES256"
}

module "ami_lifecycle_usw2" {
  source = "../../modules/ami_lifecycle"

}

module "ami_lifecycle_use1" {
  count  = contains(var.ami_regions, "us-east-1") ? 1 : 0
  source = "../../modules/ami_lifecycle"

  providers = {
    aws = aws.use1
  }
}

resource "aws_s3_object" "bigfix_folder" {
  bucket = local.secrets_bucket
  acl    = "private"
  key    = "common/soc_agents/bigfix/"
  source = "/dev/null"
}

resource "aws_s3_object" "endgame_folder" {
  bucket = local.secrets_bucket
  acl    = "private"
  key    = "common/soc_agents/endgame/"
  source = "/dev/null"
}

resource "aws_s3_object" "fireeye_folder" {
  bucket = local.secrets_bucket
  acl    = "private"
  key    = "common/soc_agents/fireeye/"
  source = "/dev/null"
}
