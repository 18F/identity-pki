provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["340731855345"] # require login-master
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  slack_events_sns_topic = "slack-events"
  iam_account_alias      = "login-master"
  account_roles_map = {
    iam_power_enabled          = false
    iam_readonly_enabled       = false
    iam_socadmin_enabled       = true
    iam_terraform_enabled      = true
    iam_billing_enabled        = true
    iam_auto_terraform_enabled = false
  }
}

module "config_password_rotation" {
  source = "../../modules/config_iam_password_rotation"
  depends_on = [
    module.main.sns_to_slack_usw2,
    module.main.sns_to_slack_use1
  ]

  config_password_rotation_name = module.main.config_password_rotation_name
  region                        = module.main.region
  config_password_rotation_code = "../../modules/config_iam_password_rotation/${module.main.config_password_rotation_code}"
  slack_events_sns_topic        = "slack-events"
}

###Verify SES identity###
module "master_ses" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=main"

  domain           = "humans.login.gov"
  zone_id          = "Z2DA4DCW3GKJVW"
  ttl_dkim_records = "1800"
}

