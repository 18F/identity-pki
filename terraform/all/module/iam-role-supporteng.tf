module "supporteng-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=995040426241ec92a1eccb391d32574ad5fc41be"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "SupportEngineer"
  enabled                         = contains(local.enabled_roles, "iam_supporteng_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = []
}
