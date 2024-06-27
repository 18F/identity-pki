provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
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
  iam_account_alias = "login-tooling-sandbox"


  slack_events_sns_topic            = "slack-events"
  splunk_oncall_cloudwatch_endpoint = var.splunk_oncall_cloudwatch_endpoint
  splunk_oncall_newrelic_endpoint   = var.splunk_oncall_newrelic_endpoint

  dnssec_zone_exists = true
  smtp_user_ready    = true

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
        AWS = "*"
      }
      Action = [
        "kms:GetPublicKey",
        "kms:DescribeKey"
      ]
      Resource = "*"
    },
    {
      Sid    = "Allow read only access for terraform"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
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
  id = "d8cfd742-5039-4074-add6-f053edafdaa3"
}

import {
  to = module.image_signing.aws_kms_alias.this
  id = "alias/image_signing_cosign_signature_key"
}

import {
  to = module.image_signing.aws_kms_key_policy.this
  id = "d8cfd742-5039-4074-add6-f053edafdaa3"
}

import {
  to = module.image_signing.aws_s3_object.keyid
  id = "s3://login-gov.secrets.034795980528-us-west-2/common/image_signing.keyid"
}

import {
  to = module.image_signing.aws_s3_object.pubkey
  id = "s3://login-gov.secrets.034795980528-us-west-2/common/image_signing.pub"
}
