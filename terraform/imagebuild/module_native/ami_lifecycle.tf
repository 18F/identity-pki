module "ami_lifecycle_usw2" {
  count  = var.ami_lifecycle_enabled ? 1 : 0
  source = "../../modules/ami_lifecycle"
}

module "ami_lifecycle_use1" {
  count  = contains(var.ami_regions, "us-east-1") && var.ami_lifecycle_enabled ? 1 : 0
  source = "../../modules/ami_lifecycle"

  providers = {
    aws = aws.use1
  }
}
