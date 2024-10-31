locals {
  region     = "us-west-2"
  account_id = "217680906704"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-prod
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

  readonly_accountids        = ["555546682965", "894947205914", "034795980528", "487317109730"] # prod and sandbox and tooling-sandbox and data-warehouse-sandbox
  prod_accountid             = "555546682965"
  ecr_repo_name              = each.value.name
  lifecycle_policies_enabled = can(each.value.lifecycle_policies_enabled) ? each.value.lifecycle_policies_enabled : true
  lifecycle_policy_settings  = can(each.value.lifecycle_policy_settings) ? each.value.lifecycle_policy_settings : { images : 10 } # Default to 10 images
  encryption_type            = "AES256"
  kms_key                    = null
  region                     = "us-west-2"
  tags                       = each.value.tags
}
