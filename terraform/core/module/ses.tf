module "ses_west_2" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/ses_dkim_r53"

  domain  = var.root_domain
  zone_id = module.common_dns.primary_zone_id
}

module "ses_east_1" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/ses_dkim_r53"
  providers = {
    aws = aws.use1
  }

  domain  = var.root_domain
  zone_id = module.common_dns.primary_zone_id
}

resource "aws_route53_record" "primary_verification_record" {
  zone_id = module.common_dns.primary_zone_id
  name    = "_amazonses.${var.root_domain}"
  type    = "TXT"
  ttl     = var.ttl_verification_record
  records = [
    module.ses_west_2.ses_token,
    module.ses_east_1.ses_token,
  ]
}

module "incoming_ses" {
  source = "../../modules/incoming_ses/"
  count  = var.ses_inbound_enabled ? 1 : 0
  # Be default this module will create a drop-no-reply, bounce-unknown, and filter rules for SES.
  # Even if all other features (usps_features_enabled,sandbox_features_enabled) are set to false.

  domain = var.root_domain
  # sandbox_features_enabled creates resources to receive inbound messages on a per account basis.
  sandbox_features_enabled = var.ses_inbound_sandbox_features_enabled
  # usps_features_enabled creates the necessary resources to ingest notifications
  # from USPS on a per environment basis.
  usps_features_enabled = var.ses_inbound_usps_features_enabled
  email_users           = var.sandbox_email_users
  email_bucket          = aws_s3_bucket.email.id
  usps_envs             = var.ses_inbound_usps_enabled_envs
}

moved {
  from = module.sandbox_ses
  to   = module.incoming_ses[0]
}
