# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
