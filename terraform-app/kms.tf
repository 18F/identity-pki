data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  # Allow root users in
  statement {
    actions = [
      "kms:*",
    ]
    principals = {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = [
      "*"
    ]
  }

  # allow key admins in
  statement {
    actions = [
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
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    principals = {
      type = "AWS"
      identifiers = ["${var.power_users}"]
    }
    resources = [
      "*"
    ]
  }

  # allow the app role to use KMS
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals = {
      type = "AWS"
      identifiers = ["${aws_iam_role.idp.arn}"]
    }
    resources = [
      "*"
    ]
  }
}

resource "aws_kms_key" "login-dot-gov-keymaker" {
  enable_key_rotation = true
  description = "${var.env_name}-login-dot-gov-keymaker"
  policy = "${data.aws_iam_policy_document.kms.json}"
}

resource "aws_kms_alias" "login-dot-gov-keymaker-alias" {
  name = "alias/${var.env_name}-login-dot-gov-keymaker"
  target_key_id = "${aws_kms_key.login-dot-gov-keymaker.key_id}"
}

