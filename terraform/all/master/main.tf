locals {
  region     = "us-west-2"
  account_id = "340731855345"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-master
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-master"

  slack_events_sns_topic = "slack-events"

  #limit_allowed_services = true  # uncomment to limit allowed services for all Roles

  account_roles_map = {
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_socadmin_enabled       = true
    iam_terraform_enabled      = true
    iam_billing_enabled        = true
    iam_auto_terraform_enabled = false
  }

  cloudwatch_retention_days                  = 2192
  cloudwatch_minimum_retention_days_scanning = 3653

  account_cloudwatch_log_groups = [
    "/var/log/messages"
  ]
}

module "config_password_rotation" {
  source = "../../modules/config_iam_password_rotation"

  config_password_rotation_name = module.main.config_password_rotation_name
  region                        = module.main.region
  config_password_rotation_code = "../../modules/config_iam_password_rotation/${module.main.config_password_rotation_code}"
}
