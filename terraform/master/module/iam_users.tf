# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=95a15c29faffffabb454881629b7a126fcad6d3c"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map = var.user_map
}
