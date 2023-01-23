provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["472911866628"] # require login-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  slack_events_sns_topic = "slack-events"
  iam_account_alias      = "login-sms-prod"
  account_roles_map = {
    iam_analytics_enabled      = true,
    iam_auto_terraform_enabled = false
  }

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
