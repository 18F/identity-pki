# Users and group memberships
module "master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=d828a788d6b8ed2b0a6f8895c9ce17433c27e550"
  #source = "../../../../identity-terraform/iam_masterusers"

  user_map               = var.user_map
}
