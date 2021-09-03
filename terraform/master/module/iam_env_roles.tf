module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=fe5cedbab370a69079261adb5e0ff1f7cd51acf8"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
