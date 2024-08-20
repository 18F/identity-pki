locals {
  region     = "us-west-2"
  account_id = "487317109730"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-analytics-sandbox
}

data "aws_caller_identity" "current" {
}

terraform {
  backend "s3" {
  }
}

module "data_warehouse" {
  source                             = "../module"
  env_name                           = "agnes"
  slack_events_sns_hook_arn          = "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-otherevents"
  slack_alarms_sns_hook_arn          = "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-otherevents"
  additional_low_priority_sns_topics = ["arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-data-warehouse-events"]
  use_spot_instances                 = 1
  autoscaling_schedule_name          = "nozero_normal"
}


