# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
