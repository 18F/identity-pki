# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=6e0d3619b3ddf7e59eb2755a267444b526df4c9a"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map               = var.user_map
}
