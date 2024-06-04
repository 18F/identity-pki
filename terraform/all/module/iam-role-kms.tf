module "kmsadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "KMSAdministrator"
  enabled                         = contains(local.enabled_roles, "iam_kmsadmin_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "KMSAdministrator"
      policy_description = "Policy for KMS administrators"
      policy_document = [
        {
          sid    = "AllowKeyAdmins"
          effect = "Allow"
          actions = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:Encrypt*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion",
          ]
          resources = [
            "*",
          ]
        },
      ]
    }
  ]
}
