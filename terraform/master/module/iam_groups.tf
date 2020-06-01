# Groups and group policy attachments

module "iam_groups" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=d828a788d6b8ed2b0a6f8895c9ce17433c27e550"
  #source = "../../../../identity-terraform/iam_assumegroup"

  group_role_map = var.group_role_map
  master_account_id = var.master_account_id
}
