module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=d828a788d6b8ed2b0a6f8895c9ce17433c27e550"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
