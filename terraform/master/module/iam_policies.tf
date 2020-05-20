#### Master "ManageYourAccount" policy
resource "aws_iam_policy" "manage_your_account" {
  name        = "ManageYourAccount"
  path        = "/"
  description = "Policy for account self management"
  policy      = data.aws_iam_policy_document.manage_your_account.json
}

data "aws_iam_policy_document" "manage_your_account" {
  statement {
    sid    = "AllowAllUsersToListAccounts"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:ListVirtualMFADevices",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "AllowAllUsersToListIAMResourcesWithMFA"
    effect = "Allow"
    actions = [
      "iam:ListPolicies",
      "iam:GetPolicyVersion",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid    = "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:DeleteAccessKey",
      "iam:DeleteLoginProfile",
      "iam:GetLoginProfile",
      "iam:GetUser",
      "iam:GetAccessKeyLastUsed",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:UpdateLoginProfile",
      "iam:ListSigningCertificates",
      "iam:DeleteSigningCertificate",
      "iam:UpdateSigningCertificate",
      "iam:UploadSigningCertificate",
      "iam:ListSSHPublicKeys",
      "iam:GetSSHPublicKey",
      "iam:DeleteSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
    ]
    resources = [
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToListOnlyTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:ListMFADevices",
    ]
    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToManageTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid    = "BlockMostAccessUnlessSignedInWithMFA"
    effect = "Deny"
    actions = [
      "iam:DeleteVirtualMFADevice",
      "iam:DeleteLoginProfile",
      "iam:DeleteAccessKey",
      "iam:DeactivateMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListSSHPublicKeys",
      "iam:DeleteSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
      "iam:ListServiceSpecificCredentials",
      "iam:GetAccountSummary",
      "iam:GetUser",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
      "iam:GetPolicyVersion",
      "sts:AssumeRole",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "false",
      ]
    }
  }
}

#### Master "FullAdministrator" policy that requires mfa device
resource "aws_iam_policy" "full_administrator" {
  name        = "FullAdministratorWithMFA"
  path        = "/"
  description = "Policy for full administrator with MFA"
  policy      = data.aws_iam_policy_document.full_administrator.json
}

data "aws_iam_policy_document" "full_administrator" {
  statement {
    sid    = "FullAdministratorWithMFA"
    effect = "Allow"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
  }
}

#### Master "SOCAdministrator" policy
resource "aws_iam_policy" "socadministrator" {
  name        = "SOCAdministrator"
  path        = "/"
  description = "Policy for SOC administrators"
  policy      = data.aws_iam_policy_document.socadministrator.json
}

data "aws_iam_policy_document" "socadministrator" {
  statement {
    sid    = "SOCAdministrator"
    effect = "Allow"
    actions = [
      "access-analyzer:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "logs:*",
      "config:*",
      "guardduty:*",
      "iam:Get*",
      "iam:List*",
      "iam:Generate*",
      "macie:*",
      "organizations:List*",
      "organizations:Describe*",
      "s3:HeadBucket",
      "s3:List*",
      "s3:Get*",
      "securityhub:*",
      "shield:*",
      "sns:*",
      "ssm:*",
      "trustedadvisor:*",
    ]
    resources = [
      "*"
    ]
  }
}

#### Master "BillingReadOnly" policy
resource "aws_iam_policy" "billing_readonly" {
  name        = "BillingReadOnly"
  path        = "/"
  description = "Policy for reporting group read-only access to Billing ui"
  policy      = data.aws_iam_policy_document.billing_readonly.json
}

data "aws_iam_policy_document" "billing_readonly" {
  statement {
    sid    = "BillingReadOnly"
    effect = "Allow"
    actions = [
      "aws-portal:ViewBilling",
    ]
    resources = [
      "*"
    ]
  }
}
