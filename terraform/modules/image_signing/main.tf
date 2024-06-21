# KMS key for signing
# key policy

# export in pem (attribute on aws_kms_public_key), put in s3 bucket in the right
# place

locals {
  admin_policy_statement = {
    Sid    = "Allow access for FullAdmins"
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator"
    }
    Action = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:Sign",
      "kms:CancelKeyDeletion"
    ]
    Resource = "*"
  }
  policy_statements = concat([local.admin_policy_statement], var.additional_policy_statements)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  description              = "image_signing Cosign Signature Key"
  customer_master_key_spec = "RSA_4096"
  key_usage                = "SIGN_VERIFY"
}

resource "aws_kms_alias" "this" {
  name          = "alias/image_signing_cosign_signature_key"
  target_key_id = aws_kms_key.this.id
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Id        = "key-default"
    Statement = local.policy_statements
  })
}

data "aws_kms_public_key" "this" {
  key_id = aws_kms_key.this.id
}

resource "aws_s3_object" "keyid" {
  bucket  = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  key     = "common/image_signing.keyid"
  content = aws_kms_key.this.id
}

resource "aws_s3_object" "pubkey" {
  bucket  = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  key     = "common/image_signing.pub"
  content = data.aws_kms_public_key.this.public_key_pem
}
