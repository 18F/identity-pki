# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map    = var.group_role_map
  master_account_id = var.master_account_id
  policy_depends_on = module.assume_roles.policy_arns
}
