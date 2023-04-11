provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["138431511372"] # require login-secops-dev
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "opsgenie_key_ready" {
  default = true
}

variable "splunk_oncall_endpoint" {
  default = "UNSET"
}

module "main" {
  source = "../module"

  opsgenie_key_ready     = var.opsgenie_key_ready
  splunk_oncall_endpoint = var.splunk_oncall_endpoint
  iam_account_alias      = "login-secops-dev"
  cloudtrail_event_selectors = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"

      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::login-gov.tf-state.138431511372-us-west-2/",
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
