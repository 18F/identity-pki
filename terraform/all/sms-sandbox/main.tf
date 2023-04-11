provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["035466892286"] # require login-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "splunk_oncall_endpoint" {
  default = "UNSET"
}

module "main" {
  source = "../module"

  iam_account_alias      = "login-sms-sandbox"
  splunk_oncall_endpoint = var.splunk_oncall_endpoint
  account_roles_map = {
    iam_analytics_enabled = true
  }

  cloudtrail_event_selectors = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"

      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::login-gov.tf-state.035466892286-us-west-2/",
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
