# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map    = var.group_role_map
  master_account_id = var.master_account_id
  policy_depends_on = module.assume_roles.policy_arns
}
