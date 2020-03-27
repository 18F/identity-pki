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

#### Assume "FullAdminstrator" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_full_administrator" {
  name        = "SandboxAssumeFullAdministrator"
  path        = "/"
  description = "Policy to allow user to assume full administrator role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_full_administrator.json
}

data "aws_iam_policy_document" "sandbox_assume_full_administrator" {
  statement {
    sid    = "SandboxAssumeFullAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/FullAdministrator",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_full_administrator" {
  name        = "ProductionAssumeFullAdministrator"
  path        = "/"
  description = "Policy to allow user to assume full administrator role in Production"
  policy      = data.aws_iam_policy_document.production_assume_full_administrator.json
}

data "aws_iam_policy_document" "production_assume_full_administrator" {
  statement {
    sid    = "ProductionAssumeFullAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/FullAdministrator",
    ]
  }
}

# sms-sandbox
resource "aws_iam_policy" "sandbox_sms_assume_full_administrator" {
  name        = "SandboxSMSAssumeFullAdministrator"
  path        = "/"
  description = "Policy to allow user to assume full administrator role in Sandbox SMS"
  policy      = data.aws_iam_policy_document.sandbox_sms_assume_full_administrator.json
}

data "aws_iam_policy_document" "sandbox_sms_assume_full_administrator" {
  statement {
    sid    = "SandboxSMSAssumeFullAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_sms_account_id}:role/FullAdministrator",
    ]
  }
}

# sms-prod
resource "aws_iam_policy" "production_sms_assume_full_administrator" {
  name        = "ProductionSMSAssumeFullAdministrator"
  path        = "/"
  description = "Policy to allow user to assume full administrator role in Production SMS"
  policy      = data.aws_iam_policy_document.production_sms_assume_full_administrator.json
}

data "aws_iam_policy_document" "production_sms_assume_full_administrator" {
  statement {
    sid    = "ProductionSMSAssumeFullAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_sms_account_id}:role/FullAdministrator",
    ]
  }
}

# analytics-prod
resource "aws_iam_policy" "production_analytics_assume_full_administrator" {
  name        = "ProductionAnalyticsAssumeFullAdministrator"
  path        = "/"
  description = "Policy to allow user to assume full administrator role in Production Analytics"
  policy      = data.aws_iam_policy_document.production_analytics_assume_full_administrator.json
}

data "aws_iam_policy_document" "production_analytics_assume_full_administrator" {
  statement {
    sid    = "ProductionAnalyticsAssumeFullAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_analytics_account_id}:role/FullAdministrator",
    ]
  }
}

#### Assume "PowerUser" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_power_user" {
  name        = "SandboxAssumePower"
  path        = "/"
  description = "Policy to allow user to assume power role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_power_user.json
}

data "aws_iam_policy_document" "sandbox_assume_power_user" {
  statement {
    sid    = "SandboxAssumePowerUser"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/PowerUser",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_power_user" {
  name        = "ProductionAssumePowerUser"
  path        = "/"
  description = "Policy to allow user to assume power role in Production"
  policy      = data.aws_iam_policy_document.production_assume_power_user.json
}

data "aws_iam_policy_document" "production_assume_power_user" {
  statement {
    sid    = "ProductionAssumePowerUser"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/PowerUser",
    ]
  }
}

#### Assume "ReadOnly" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_readonly" {
  name        = "SandboxAssumeReadOnly"
  path        = "/"
  description = "Policy to allow user to assume readonly role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_readonly.json
}

data "aws_iam_policy_document" "sandbox_assume_readonly" {
  statement {
    sid    = "SandboxAssumeReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/ReadOnly",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_readonly" {
  name        = "ProductionAssumeReadOnly"
  path        = "/"
  description = "Policy to allow user to assume readonly in Production"
  policy      = data.aws_iam_policy_document.production_assume_readonly.json
}

data "aws_iam_policy_document" "production_assume_readonly" {
  statement {
    sid    = "ProductionAssumeReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/ReadOnly",
    ]
  }
}

#### Assume "AppDev" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_appdev" {
  name        = "SandboxAssumeAppDev"
  path        = "/"
  description = "Policy to allow user to assume appdev role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_appdev.json
}

data "aws_iam_policy_document" "sandbox_assume_appdev" {
  statement {
    sid    = "SandboxAssumeAppDev"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/AppDev",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_appdev" {
  name        = "ProductionAssumeAppDev"
  path        = "/"
  description = "Policy to allow user to assume appdev in Production"
  policy      = data.aws_iam_policy_document.production_assume_appdev.json
}

data "aws_iam_policy_document" "production_assume_appdev" {
  statement {
    sid    = "ProductionAssumeAppDev"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/AppDev",
    ]
  }
}

#### Assume "ReportingReadOnly" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_reporting_ro" {
  name        = "SandboxAssumeReportsReadOnly"
  path        = "/"
  description = "Policy to allow user to assume reporting read-only role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_reporting_ro.json
}

data "aws_iam_policy_document" "sandbox_assume_reporting_ro" {
  statement {
    sid    = "SandboxAssumeReportsReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/ReportsReadOnly",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_reporting_ro" {
  name        = "ProductionAssumeReportsReadOnly"
  path        = "/"
  description = "Policy to allow user to assume reporting read-only role in Production"
  policy      = data.aws_iam_policy_document.production_assume_reporting_ro.json
}

data "aws_iam_policy_document" "production_assume_reporting_ro" {
  statement {
    sid    = "ProductionAssumeReportsReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/ReportsReadOnly",
    ]
  }
}

#### Assume "SOCAdminstrator" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_socadministrator" {
  name        = "SandboxAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to allow user to assume SOCAdministrator in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_socadministrator.json
}

data "aws_iam_policy_document" "sandbox_assume_socadministrator" {
  statement {
    sid    = "SandboxAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/SOCAdministrator"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# prod
resource "aws_iam_policy" "production_assume_socadministrator" {
  name        = "ProductionAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to allow user to assume SOCAdministrator in Production"
  policy      = data.aws_iam_policy_document.production_assume_socadministrator.json
}

data "aws_iam_policy_document" "production_assume_socadministrator" {
  statement {
    sid    = "ProductionAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/SOCAdministrator"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# sms-sandbox
resource "aws_iam_policy" "sandbox_sms_assume_socadministrator" {
  name        = "SandboxSMSAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to allow user to assume SOCAdministrator role in Sandbox SMS"
  policy      = data.aws_iam_policy_document.sandbox_sms_assume_socadministrator.json
}

data "aws_iam_policy_document" "sandbox_sms_assume_socadministrator" {
  statement {
    sid    = "SandboxAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_sms_account_id}:role/SOCAdministrator"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# sms-prod
resource "aws_iam_policy" "production_sms_assume_socadministrator" {
  name        = "ProductionSMSAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to allow user to assume SOCAdministrator role in Production SMS"
  policy      = data.aws_iam_policy_document.production_sms_assume_socadministrator.json
}

data "aws_iam_policy_document" "production_sms_assume_socadministrator" {
  statement {
    sid    = "ProductionAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.production_sms_account_id}:role/SOCAdministrator"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# analytics
resource "aws_iam_policy" "production_analytics_assume_socadministrator" {
  name        = "ProductionAnalyticsAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to allow user to assume SOCAdministrator role in Production Analytics"
  policy      = data.aws_iam_policy_document.production_analytics_assume_socadministrator.json
}

data "aws_iam_policy_document" "production_analytics_assume_socadministrator" {
  statement {
    sid    = "ProductionAnalyticsAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.production_analytics_account_id}:role/SOCAdministrator"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

#### Assume "BillingReadOnly" policies
# sandbox
resource "aws_iam_policy" "sandbox_assume_billing_ro" {
  name        = "SandboxAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to allow user to assume billing read-only role in Sandbox"
  policy      = data.aws_iam_policy_document.sandbox_assume_billing_ro.json
}

data "aws_iam_policy_document" "sandbox_assume_billing_ro" {
  statement {
    sid    = "SandboxAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_account_id}:role/BillingReadOnly",
    ]
  }
}

# prod
resource "aws_iam_policy" "production_assume_billing_ro" {
  name        = "ProductionAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to allow user to assume billing read-only role in Production"
  policy      = data.aws_iam_policy_document.production_assume_billing_ro.json
}

data "aws_iam_policy_document" "production_assume_billing_ro" {
  statement {
    sid    = "ProductionAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.production_account_id}:role/BillingReadOnly",
    ]
  }
}

# sms-sandbox
resource "aws_iam_policy" "sandbox_sms_assume_billing_ro" {
  name        = "SandboxSMSAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to allow user to assume BillingReadOnly role in Sandbox SMS"
  policy      = data.aws_iam_policy_document.sandbox_sms_assume_billing_ro.json
}

data "aws_iam_policy_document" "sandbox_sms_assume_billing_ro" {
  statement {
    sid    = "SandboxSMSAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.sandbox_sms_account_id}:role/BillingReadOnly"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# sms-prod
resource "aws_iam_policy" "production_sms_assume_billing_ro" {
  name        = "ProductionSMSAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to allow user to assume BillingReadOnly role in Production SMS"
  policy      = data.aws_iam_policy_document.production_sms_assume_billing_ro.json
}

data "aws_iam_policy_document" "production_sms_assume_billing_ro" {
  statement {
    sid    = "ProductionSMSAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.production_sms_account_id}:role/BillingReadOnly"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# analytics-prod
resource "aws_iam_policy" "production_analytics_assume_billing_ro" {
  name        = "ProductionAnalyticsAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to allow user to assume BillingReadOnly role in Production Analytics"
  policy      = data.aws_iam_policy_document.production_analytics_assume_billing_ro.json
}

data "aws_iam_policy_document" "production_analytics_assume_billing_ro" {
  statement {
    sid    = "ProductionAnalyticsAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:aws:iam::${var.production_analytics_account_id}:role/BillingReadOnly"
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}
