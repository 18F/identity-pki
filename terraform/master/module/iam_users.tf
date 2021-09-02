# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=91eadab865ca59a2998387681ca83ac401b7c352"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map         = var.user_map
  group_depends_on = module.iam_groups.group_names
}
