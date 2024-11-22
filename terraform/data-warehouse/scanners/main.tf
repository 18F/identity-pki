locals {
  region     = "us-west-2"
  account_id = "487317109730"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-analytics-sandbox
}

terraform {
  backend "s3" {
  }
}

module "data_warehouse" {
  source                                  = "../module"
  env_name                                = "scanners"
  slack_events_sns_hook_arn               = "arn:aws:sns:us-west-2:${local.account_id}:slack-otherevents"
  slack_alarms_sns_hook_arn               = "arn:aws:sns:us-west-2:${local.account_id}:slack-otherevents"
  additional_low_priority_sns_topics      = ["arn:aws:sns:us-west-2:${local.account_id}:slack-data-warehouse-otherevents"]
  additional_moderate_priority_sns_topics = ["arn:aws:sns:us-west-2:${local.account_id}:slack-data-warehouse-otherevents"]
  use_spot_instances                      = 1
  autoscaling_schedule_name               = "nozero_normal"
  gitlab_enabled                          = true
  gitlab_runner_enabled                   = true
}
