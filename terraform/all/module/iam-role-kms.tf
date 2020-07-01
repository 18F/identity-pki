module "kmsadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "KMSAdministrator"
  enabled                  = lookup(
                                merge(local.role_enabled_defaults,var.account_roles_map),
                                "iam_kmsadmin_enabled",
                                lookup(local.role_enabled_defaults,"iam_kmsadmin_enabled")
                              )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "KMSAdministrator"
      policy_description = "Policy for KMS administrators"
      policy_document = [
        {
          sid = "AllowKeyAdmins"
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
