module "supporteng-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"

  role_name = "SupportEngineer"
  enabled = lookup(
    merge(local.role_enabled_defaults, var.account_roles_map),
    "iam_supporteng_enabled",
    lookup(local.role_enabled_defaults, "iam_supporteng_enabled")
  )
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = []
}
