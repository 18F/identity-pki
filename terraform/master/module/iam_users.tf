# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=7330e23d026ed88895e8ffa632371c38ab6a765c"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map = var.user_map
}
