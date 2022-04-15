module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=4d21d72ba1624f0b0b78813188f71ed68363b587"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
