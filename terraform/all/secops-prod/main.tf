provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["217680906704"] # require login-secops-prod
  profile             = "login-secops-prod"
  version             = "~> 2.67.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source                       = "../module"

  iam_account_alias  = "login-secops-prod"
  account_roles_map = {
    iam_appdev_enabled = false
  }

  cloudtrail_event_selectors  = [
    {
      include_management_events = false
      read_write_type           = "WriteOnly"

      data_resources = [
        {
          type = "AWS::S3::Object"
          values = [
            "arn:aws:s3:::login-gov.tf-state.217680906704-us-west-2/",
          ]
        }
      ]
    }   
  ]
}
