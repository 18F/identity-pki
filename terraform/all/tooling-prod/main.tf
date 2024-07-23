locals {
  region     = "us-west-2"
  account_id = "217680906704"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id] # require login-tooling-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

data "aws_caller_identity" "current" {}

variable "splunk_oncall_cloudwatch_endpoint" {
  default = "UNSET"
}

variable "splunk_oncall_newrelic_endpoint" {
  default = "UNSET"
}

module "main" {
  source            = "../module"
  iam_account_alias = "login-tooling-prod"

  splunk_oncall_cloudwatch_endpoint = var.splunk_oncall_cloudwatch_endpoint
  splunk_oncall_newrelic_endpoint   = var.splunk_oncall_newrelic_endpoint

  smtp_user_ready = true

  #limit_allowed_services = true  # uncomment to limit allowed services for all Roles

  cloudtrail_event_selectors = [
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
    },
    {
      include_management_events = true
      read_write_type           = "All"

      data_resources = []
    }
  ]

  ssm_document_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
  }

  ssm_command_access_map = {
    "FullAdministrator" = [{ "*" = ["*"] }],
    "PowerUser"         = [{ "*" = ["*"] }],
    "Terraform"         = [{ "*" = ["*"] }],
  }
}

module "image_signing" {
  source = "../../modules/image_signing"

  additional_policy_statements = [
    {
      Sid    = "Allow everybody to get pubkey for verification"
      Effect = "Allow"
      Principal = {
        AWS = ["*"]
      }
      Action = [
        "kms:GetPublicKey",
        "kms:DescribeKey"
      ]
      Resource = "*"
    },
    {
      Sid    = "Allow Gitlab Build Pool to use key to sign/verify images"
      Effect = "Allow"
      Principal = {
        AWS = [
          "arn:aws:iam::217680906704:role/gitstaging-build-pool_gitlab_runner_role",
          "arn:aws:iam::217680906704:role/production-build-pool_gitlab_runner_role"
        ]
      }
      Action = [
        "kms:Verify"
      ]
      Resource = "*"
    },
    {
      Sid    = "Allow read only access for terraform"
      Effect = "Allow"
      Principal = {
        AWS = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
        ]
      }
      Action = [
        "kms:Describe*",
        "kms:List*",
        "kms:Get*",
      ]
      Resource = "*"
    }

  ]
}

import {
  to = module.image_signing.aws_kms_key.this
  id = "02ebdaa7-0c5a-4d30-937a-b19b354d4940"
}

import {
  to = module.image_signing.aws_kms_alias.this
  id = "alias/image_signing_cosign_signature_key"
}

import {
  to = module.image_signing.aws_kms_key_policy.this
  id = "02ebdaa7-0c5a-4d30-937a-b19b354d4940"
}

import {
  to = module.image_signing.aws_s3_object.keyid
  id = "s3://login-gov.secrets.217680906704-us-west-2/common/image_signing.keyid"
}

import {
  to = module.image_signing.aws_s3_object.pubkey
  id = "s3://login-gov.secrets.217680906704-us-west-2/common/image_signing.pub"
}
