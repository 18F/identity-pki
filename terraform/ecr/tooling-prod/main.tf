provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

locals {
  repos = yamldecode(file("${path.module}/repos.yml")).repos
}

module "settings" {
  source = "../module-ecr-global-settings"

  continuous_scan_filter = "*"
  region                 = "us-west-2"
  scan_on_push_filter    = "*"
}

module "repos" {
  for_each = local.repos
  source   = "../module-ecr-repo"

  readonly_accountids = ["555546682965", "894947205914", "034795980528"] # prod and sandbox and tooling-sandbox
  prod_accountid      = "555546682965"
  ecr_repo_name       = each.value.name
  encryption_type     = "AES256"
  kms_key             = null
  region              = "us-west-2"
  tags                = each.value.tags
}
