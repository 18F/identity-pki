provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["555546682965"] # require identity-prod
  profile             = "login.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  lambda_audit_github_enabled  = 0
  lambda_audit_aws_enabled     = 0
  state_lock_table             = "terraform_locks"
  slack_events_sns_hook_arn    = "arn:aws:sns:us-west-2:555546682965:slack-identity-events"
  root_domain                  = "login.gov"
  static_cloudfront_name       = "db1mat7gaslfp.cloudfront.net"
  design_cloudfront_name       = "d28khhcfeuwd3y.cloudfront.net"
  developers_cloudfront_name   = "d26qb7on2m22yd.cloudfront.net"
  google_site_verification_txt = "x8WM0Sy9Q4EmkHypuULXjTibNOJmPEoOxDGUmBppws8"
  mx_provider                  = "google-g-suite"
  lambda_audit_github_debug    = 0

  # Users allowed to administer KMS keys
  # populate this with:
  #   aws iam get-group --group-name identity-power --output text | cut -f2
  power_users = [
    "arn:aws:iam::555546682965:user/rajat.varuni",
    "arn:aws:iam::555546682965:user/steve.urciuoli",
    "arn:aws:iam::555546682965:user/jonathan.hooper",
    "arn:aws:iam::555546682965:user/brian.crissup",
    "arn:aws:iam::555546682965:user/mossadeq.zia"
  ]
}
