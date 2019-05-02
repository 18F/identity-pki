# manage your account policy

data "aws_iam_policy_document" "list_user_accounts" {
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
}

data "aws_iam_policy_document" "manage_user_account" {
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
}

data "aws_iam_policy_document" "user_list_mfa" {
    statement {
        sid = "AllowIndividualUserToListOnlyTeirOwnMFA"
        effect = "Allow"
        actions = [
            "iam:ListMFADevices"
        ]
        resources = [
            "arn:aws:iam::*:mfa/*",
            "arn:aws:iam::*:user/$${aws:username}"
        ]
    }
}

data "aws_iam_policy_document" "manage_user_mfa" {
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
            "arn:aws:iam::*user/$${aws:username}"
        ]
    }
}

data "aws_iam_policy_document" "user_disable_mfa" {
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
}

data "aws_iam_policy_document" "restrict_user_without_mfa" {
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
    }
}

#assume role
