module "quaratine_process" {
  source = "../../../../identity-terraform/ec2_quarantine"

  providers = {
    aws.primary   = aws.usw2
    aws.secondary = aws.use1
  }
}
