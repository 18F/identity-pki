module "supporteng-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  role_name = "SupportEngineer"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_supporteng_enabled",
    lookup(local.role_enabled_defaults, "iam_supporteng_enabled")
  )
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : "",
  ])

  iam_policies = []
}