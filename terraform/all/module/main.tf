resource "aws_iam_account_alias" "standard_alias" {
  account_alias = var.iam_account_alias
}

data "aws_caller_identity" "current" {}

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
  statement {
    sid = "PassSessionTagFromMasterAccount"
    actions = [
      "sts:TagSession"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.master_account_id}:root"
      ]
    }
  }
}

# used for assuming of AutoTerraform role from tooling
data "aws_iam_policy_document" "autotf_assumerole" {
  statement {
    sid = "AssumeTerraformRoleFromAutotfRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.tooling_account_id}:role/auto_terraform",
        "arn:aws:iam::${var.toolingprod_account_id}:role/auto_terraform"
      ]
    }
  }
}

# get DNSSEC prevent-delete policy if dnssec_zone_exists = true
data "aws_iam_policy" "dnssec_disable_prevent" {
  count = var.dnssec_zone_exists ? 1 : 0

  name = "DNSSecDisablePrevent"
}

locals {
  bucket_name_prefix       = "login-gov"
  secrets_bucket_type      = "secrets"
  cert_secrets_bucket_type = "internal-certs"
}

# account-wide password policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 32
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  max_password_age               = 90
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  hard_expiry                    = false # Default noted in case we change later
}

# FedRAMP Requirements (https://github.com/18F/identity-security-private/issues/1932)
# Minimum password length is 32 characters
# Require at least one uppercase letter from Latin alphabet (A-Z)
# Require at least one lowercase letter from Latin alphabet (a-Z)
# Require at least one number
# Require at least one non-alphanumeric character ()
# Password expires in 90 day(s)
# Allow users to change their own password
# Remember last 24 password(s) and prevent reuse
