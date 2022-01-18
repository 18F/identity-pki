# Users and group memberships
module "master_users" {
  #source = "github.com/18F/identity-terraform//iam_masterusers?ref=3485c49ef8c1cdeb50bd101b7926dca8d26d8ded"
  source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
