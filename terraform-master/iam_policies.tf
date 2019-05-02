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
        sid = "AllowIndividualUserToSeeAndManagaeOnlyTheirOwnAccountInformation"
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
            "iam:UploadSSHPublicKey"
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
            "iam:CreateVirtualMFADevice",
            "iam:DeleteVirtualMFADevice",
            "iam:ListVirtualMFADevices",
            "iam:EnableMFADevice",
            "iam:ResyncMFADevice",
            "iam:ListAccountAliases",
            "iam:ListUsers",
            "iam:ListSSHPublicKeys",
            "iam:ListAccessKeys",
            "iam:GetAccessKeyLastUsed",
            "iam:ListServiceSpecificCredentials",
            "iam:ListMFADevices",
            "iam:GetAccountSummary",
            "sts:GetSessionToken"
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

resource "aws_iam_policy" "assume_full_administrator" {
    name = "AssumeFullAdministator"
    path = "/"
    description = "Policy to assign that permits user to assume full administrator role"
    policy = "${data.aws_iam_policy_document.assume_full_administrator.json}"
}

data "aws_iam_policy_document" "assume_full_administrator" {
    statement {
        sid = "AssumeFullAdministratorWithMFA"
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = [
            "${aws_iam_role.assume_full_administrator.arn}"
        ]
    }
}