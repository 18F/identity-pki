module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=4c2fac72c84aa99590cc5690e04e55fc7a98872f"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
