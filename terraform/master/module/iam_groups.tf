# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=6e0d3619b3ddf7e59eb2755a267444b526df4c9a"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map = var.group_role_map
  master_account_id = var.master_account_id
}
