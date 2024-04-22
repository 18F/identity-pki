# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=e10d7e8c0c9b339b6526050ee5ac4c9419c18c99"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map             = var.user_map
  group_depends_on     = module.iam_groups.group_names
  default_email_domain = var.default_email_domain
}
