module "ses_west_2" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  #source = "../../../../identity-terraform/ses_dkim_r53"

  domain  = var.root_domain
  zone_id = module.common_dns.primary_zone_id
}

module "ses_east_1" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
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
