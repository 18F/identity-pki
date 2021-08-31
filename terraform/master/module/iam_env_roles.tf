module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=da46bc0d5442ac1b6403d48ed5d022aa88530e39"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
