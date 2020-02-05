provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require identity-sandbox
  profile             = "identitysandbox.gov"
  version             = "~> 2.37.0"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  state_lock_table            = "terraform_locks"
  slack_events_sns_hook_arn   = "arn:aws:sns:us-west-2:894947205914:identity-events"
  root_domain                 = "identitysandbox.gov"
  mx_provider                 = "amazon-ses-inbound.us-west-2"
  sandbox_ses_inbound_enabled = 1

  # Users allowed to administer KMS keys
  # populate this with:
  #   aws iam get-group --group-name identity-power --output text | cut -f2
  power_users = [
    "arn:aws:iam::894947205914:user/steve.urciuoli",
    "arn:aws:iam::894947205914:user/brett.mcparland",
    "arn:aws:iam::894947205914:user/rajat.varuni",
    "arn:aws:iam::894947205914:user/justin.grevich",
    "arn:aws:iam::894947205914:user/brian.crissup",
    "arn:aws:iam::894947205914:user/mossadeq.zia",
    "arn:aws:iam::894947205914:user/jonathan.hooper"
  ]
}
