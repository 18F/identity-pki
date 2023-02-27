# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
