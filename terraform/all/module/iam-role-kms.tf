module "kmsadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"

  role_name = "KMSAdministrator"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_kmsadmin_enabled",
    lookup(local.role_enabled_defaults, "iam_kmsadmin_enabled")
  )
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : "",
  ])

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
