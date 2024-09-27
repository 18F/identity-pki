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
  source                                  = "../module"
  env_name                                = "int"
  slack_events_sns_hook_arn               = "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-events"
  slack_alarms_sns_hook_arn               = "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-events"
  additional_low_priority_sns_topics      = ["arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-data-warehouse-events"]
  additional_moderate_priority_sns_topics = ["arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-data-warehouse-events"]
  use_spot_instances                      = 0
  autoscaling_schedule_name               = "nozero_normal"
}


