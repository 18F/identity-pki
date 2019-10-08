provider "aws" {
  region = "us-west-2"
  allowed_account_ids = ["340731855345"] # require identity-master
  profile = "identity-master"

  #assume_role {
  #  role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  #  session_name = "SESSION_NAME"
  #  external_id  = "EXTERNAL_ID"
  #}

  version = "~> 2.29"
}

# Stub remote config
terraform {
  backend "s3" {
  }

  # allowed terraform version
  required_version = "~> 0.11.7"
}

module "main" {
  source = "../module"

  region = "us-west-2"
  sandbox_account_id = "894947205914"
  production_account_id = "555546682965"

}
