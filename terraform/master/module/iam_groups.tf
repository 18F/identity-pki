# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map    = var.group_role_map
  master_account_id = var.master_account_id
  policy_depends_on = module.assume_roles.policy_arns
}
