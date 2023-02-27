module "supporteng-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name = "SupportEngineer"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_supporteng_enabled",
    lookup(local.role_enabled_defaults, "iam_supporteng_enabled")
  )
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  permissions_boundary_policy_arn = var.permission_boundary_policy_name != "" ? data.aws_iam_policy.permission_boundary_policy[0].arn : ""
  custom_policy_arns = compact([
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
    var.dnssec_zone_exists ? data.aws_iam_policy.dnssec_disable_prevent[0].arn : "",
  ])

  iam_policies = []
}
