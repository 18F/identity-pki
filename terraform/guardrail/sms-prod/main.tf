provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["472911866628"] # require login-prod
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

}
