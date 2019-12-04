# manage your account policy
resource "aws_iam_policy" "manage_your_account"
{
    name = "ManageYourAccount"
    path = "/"
    description = "Policy for account self management"
    policy = "${data.aws_iam_policy_document.manage_your_account.json}"
}

# manage your account policy statements
data "aws_iam_policy_document" "manage_your_account" {
    statement {
        sid = "AllowAllUsersToListAccounts"
        effect = "Allow"
        actions = [
            "iam:ListAccountAliases",
            "iam:ListUsers",
            "iam:ListVirtualMFADevices",
            "iam:GetAccountPasswordPolicy",
            "iam:GetAccountSummary"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        sid = "AllowAllUsersToListIAMResourcesWithMFA"
        effect = "Allow"
        actions = [
            "iam:ListPolicies",
            "iam:GetPolicyVersion"
        ]
        resources = [
            "*"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
    statement {
        sid = "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation"
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
            "iam:ListGroupsForUser"
        ]
        resources = [
            "arn:aws:iam::*:user/$${aws:username}"
        ]
    }
    statement {
        sid = "AllowIndividualUserToListOnlyTheirOwnMFA"
        effect = "Allow"
        actions = [
            "iam:ListMFADevices"
        ]
        resources = [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
        ]
    }
    statement {
        sid = "AllowIndividualUserToManageTheirOwnMFA"
        effect = "Allow"
        actions = [
            "iam:CreateVirtualMFADevice",
            "iam:DeleteVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ResyncMFADevice"
        ]
        resources = [
            "arn:aws:iam::*:mfa/$${aws:username}",
            "arn:aws:iam::*:user/$${aws:username}"
        ]
    }
    statement {
        sid = "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
        effect = "Allow"
        actions = [
            "iam:DeactivateMFADevice"
        ]
        resources = [
            "arn:aws:iam::*:mfa/$${aws:username}",
            "arn:aws:iam::*:user/$${aws:username}"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
    statement {
        sid = "BlockMostAccessUnlessSignedInWithMFA"
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
            "sts:AssumeRole"
        ]
        resources = [
            "*"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "false"
            ]
        }
    }
}

# full admin policy that requires mfa device
resource "aws_iam_policy" "full_administrator"
{
    name = "FullAdministratorWithMFA"
    path = "/"
    description = "Policy for full administrator with MFA"
    policy = "${data.aws_iam_policy_document.full_administrator.json}"
}

data "aws_iam_policy_document" "full_administrator" {
    statement {
        sid = "FullAdministratorWithMFA"
        effect = "Allow"
        actions = [
            "*"
        ]
        resources = [
            "*"
        ]
        condition = {
            test = "Bool"
            variable = "aws:MultiFactorAuthPresent"
            values = [
                "true"
            ]
        }
    }
}

resource "aws_iam_policy" "sandbox_assume_full_administrator" {
    name = "SandboxAssumeFullAdministrator"
    path = "/"
    description = "Policy to allow user to assume full administrator role in Sandbox"
    policy = "${data.aws_iam_policy_document.sandbox_assume_full_administrator.json}"
}

data "aws_iam_policy_document" "sandbox_assume_full_administrator" {
    statement {
        sid = "SandboxAssumeFullAdministrator"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.sandbox_account_id}:role/FullAdministrator"
        ]
    }
}

resource "aws_iam_policy" "production_assume_full_administrator" {
    name = "ProductionAssumeFullAdministrator"
    path = "/"
    description = "Policy to allow user to assume full administrator role in Production"
    policy = "${data.aws_iam_policy_document.sandbox_assume_full_administrator.json}"
}

data "aws_iam_policy_document" "production_assume_full_administrator" {
    statement {
        sid = "ProductionAssumeFullAdministrator"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.production_account_id}:role/FullAdministrator"
        ]
    }
}

resource "aws_iam_policy" "sandbox_assume_power_user" {
    name = "SandboxAssumePower"
    path = "/"
    description = "Policy to allow user to assume power role in Sandbox"
    policy = "${data.aws_iam_policy_document.sandbox_assume_power_user.json}"
}

data "aws_iam_policy_document" "sandbox_assume_power_user" {
    statement {
        sid = "SandboxAssumePowerUser"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.sandbox_account_id}:role/PowerUser"
        ]
    }
}

resource "aws_iam_policy" "production_assume_power_user" {
    name = "ProductionAssumePowerUser"
    path = "/"
    description = "Policy to allow user to assume power role in Production"
    policy = "${data.aws_iam_policy_document.production_assume_power_user.json}"
}

data "aws_iam_policy_document" "production_assume_power_user" {
    statement {
        sid = "ProductionAssumePowerUser"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.production_account_id}:role/PowerUser"
        ]
    }
}

resource "aws_iam_policy" "sandbox_assume_readonly" {
    name = "SandboxAssumeReadOnly"
    path = "/"
    description = "Policy to allow user to assume readonly role in Sandbox"
    policy = "${data.aws_iam_policy_document.sandbox_assume_readonly.json}"
}

data "aws_iam_policy_document" "sandbox_assume_readonly" {
    statement {
        sid = "SandboxAssumeReadOnly"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.sandbox_account_id}:role/ReadOnly"
        ]
    }
}

resource "aws_iam_policy" "production_assume_readonly" {
    name = "ProductionAssumeReadOnly"
    path = "/"
    description = "Policy to allow user to assume readonly in Production"
    policy = "${data.aws_iam_policy_document.production_assume_readonly.json}"
}

data "aws_iam_policy_document" "production_assume_readonly" {
    statement {
        sid = "ProductionAssumeReadOnly"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.production_account_id}:role/ReadOnly"
        ]
    }
}

resource "aws_iam_policy" "sandbox_assume_appdev" {
    name = "SandboxAssumeAppDev"
    path = "/"
    description = "Policy to allow user to assume appdev role in Sandbox"
    policy = "${data.aws_iam_policy_document.sandbox_assume_appdev.json}"
}

data "aws_iam_policy_document" "sandbox_assume_appdev" {
    statement {
        sid = "SandboxAssumeAppDev"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.sandbox_account_id}:role/AppDev"
        ]
    }
}

resource "aws_iam_policy" "production_assume_appdev" {
    name = "ProductionAssumeAppDev"
    path = "/"
    description = "Policy to allow user to assume appdev in Production"
    policy = "${data.aws_iam_policy_document.production_assume_appdev.json}"
}

data "aws_iam_policy_document" "production_assume_appdev" {
    statement {
        sid = "ProductionAssumeAppDev"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.production_account_id}:role/AppDev"
        ]
    }
}

resource "aws_iam_policy" "sandbox_assume_reporting_ro" {
    name = "SandboxAssumeReportsReadOnly"
    path = "/"
    description = "Policy to allow user to assume reporting read-only role in Sandbox"
    policy = "${data.aws_iam_policy_document.sandbox_assume_reporting_ro.json}"
}

data "aws_iam_policy_document" "sandbox_assume_reporting_ro" {
    statement {
        sid = "SandboxAssumeReportsReadOnly"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.sandbox_account_id}:role/ReportsReadOnly"
        ]
    }
}

resource "aws_iam_policy" "production_assume_reporting_ro" {
    name = "ProductionAssumeReportsReadOnly"
    path = "/"
    description = "Policy to allow user to assume reporting read-only role in Production"
    policy = "${data.aws_iam_policy_document.production_assume_reporting_ro.json}"
}

data "aws_iam_policy_document" "production_assume_reporting_ro" {
    statement {
        sid = "ProductionAssumeReportsReadOnly"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "arn:aws:iam::${var.production_account_id}:role/ReportsReadOnly"
        ]
    }
}
