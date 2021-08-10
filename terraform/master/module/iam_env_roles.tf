module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=ab7f9458f9e8fbd758e2b3d6f046266a8f51c536"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
