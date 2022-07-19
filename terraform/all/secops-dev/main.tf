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

module "main" {
  source             = "../module"
  opsgenie_key_ready = var.opsgenie_key_ready

  # comment out once SOC team approves access to CW log group
  soc_logs_enabled = false

  iam_account_alias = "login-secops-dev"

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
    }
  ]
}
