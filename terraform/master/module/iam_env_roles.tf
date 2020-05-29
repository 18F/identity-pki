module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=7330e23d026ed88895e8ffa632371c38ab6a765c"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
