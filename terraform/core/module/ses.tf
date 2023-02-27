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

# Inbound email delivery to S3 - Only for non-prod use
module "sandbox_ses" {
  source = "../../modules/sandbox_ses/"

  domain       = var.root_domain
  enabled      = var.sandbox_ses_inbound_enabled
  email_users  = var.sandbox_ses_email_users
  email_bucket = aws_s3_bucket.email.id
  usps_envs    = var.sandbox_ses_usps_enabled_envs
}
