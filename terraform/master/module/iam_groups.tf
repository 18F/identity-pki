# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=7330e23d026ed88895e8ffa632371c38ab6a765c"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map = var.group_role_map
  master_account_id = var.master_account_id
}
