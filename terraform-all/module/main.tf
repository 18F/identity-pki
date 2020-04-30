# AWS provider is inherited from per-env main.tf rather than defined here, due
# to https://github.com/hashicorp/terraform/issues/13018

provider "external" { version = "~> 1.2" }
provider "null" { version = "~> 2.1.2" }
provider "template" { version = "~> 2.1.2" }

resource "aws_iam_account_alias" "standard_alias" {
  account_alias = var.iam_account_alias
}

# allow assuming of roles from login-master
data "aws_iam_policy_document" "master_account_assumerole" {
  statement {
    sid = "AssumeRoleFromMasterAccount"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.master_account_id}:root"
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}
