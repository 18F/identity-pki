# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
