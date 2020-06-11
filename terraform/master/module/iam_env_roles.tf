module "assume_roles" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=9a7455b7e345f141689a10e8c14ca8ba8efbdbab"
  #source = "../../../../identity-terraform/iam_masterassume"

  role_list         = var.role_list
  aws_account_types = var.aws_account_types
}
