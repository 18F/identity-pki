locals {
  region     = "us-west-2"
  account_id = "472911866628"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-sms-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-sms-prod"

  slack_events_sns_topic = "slack-events"

  #limit_allowed_services = true  # uncomment to limit allowed services for all Roles

  account_roles_map = {
    iam_analytics_enabled      = true,
    iam_auto_terraform_enabled = false
  }

  cloudwatch_minimum_retention_days_scanning = 3653

  cloudtrail_event_selectors = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"

      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::login-gov.tf-state.472911866628-us-west-2/",
          ]
        }
      ]
    },
    {
      include_management_events = true
      read_write_type           = "All"

      data_resources = []
    }
  ]
}
