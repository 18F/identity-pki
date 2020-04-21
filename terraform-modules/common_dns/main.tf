variable "domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov.'"
}

variable "static_cloudfront_name" {
  description = "Static site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "design_cloudfront_name" {
  description = "Design site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "developers_cloudfront_name" {
  description = "Developers site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "cloudfront_zone_id" {
  description = "Static site Cloudfront Zone ID, e.g. ZABCDEFG1234"
  default     = "Z2FDTNDATAQYW2" # Zone ID for all cloudfront sites?
}

variable "google_site_verification_txt" {
  description = "Google site verification text to put in TXT record"
  default     = ""
}

variable "mx_provider" {
  description = "Which provider to use for MX records (see mx_record_map)"
}

variable "mx_record_map" {
  description = "Mapping of provider name to comma-separated MX records"
  type        = map(string)
  default = {
    "google-g-suite"               = "10 aspmx.l.google.com.,20 alt1.aspmx.l.google.com.,20 alt2.aspmx.l.google.com.,30 aspmx2.googlemail.com.,30 aspmx3.googlemail.com.,30 aspmx4.googlemail.com.,30 aspmx5.googlemail.com."
    "amazon-ses-inbound.us-west-2" = "10 inbound-smtp.us-west-2.amazonaws.com."
  }
}

resource "aws_route53_zone" "primary" {
  # domain, ensuring it has a trailing "."
  name = replace(var.domain, "/\\.?$/", ".")
}

output "primary_zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "primary_domain" {
  value = var.domain
}

output "primary_name_servers" {
  value = [
    aws_route53_zone.primary.name_servers[0],
    aws_route53_zone.primary.name_servers[1],
    aws_route53_zone.primary.name_servers[2],
    aws_route53_zone.primary.name_servers[3],
  ]
}

resource "aws_route53_record" "a_root" {
  name    = var.domain
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.static_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "a_www" {
  name    = "www.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.static_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "a_design" {
  name    = "design.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.design_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "a_developers" {
  name    = "developers.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.developers_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "mx_google" {
  name    = var.domain
  records = split(",", var.mx_record_map[var.mx_provider])
  ttl     = "3600"
  type    = "MX"
  zone_id = aws_route53_zone.primary.zone_id
}

# Root TXT records, including SPF.
# TODO: remove GSA? All mail should be from SES or Google.
resource "aws_route53_record" "txt" {
  name    = var.domain
  records = ["google-site-verification=${var.google_site_verification_txt}", "v=spf1 include:amazonses.com include:_spf.google.com ~all"]
  ttl     = "900"
  type    = "TXT"
  zone_id = aws_route53_zone.primary.zone_id
}

# Add a record under login.gov saying it's OK to send reports for
# identitysandbox.gov to login.gov.
# https://space.dmarcian.com/what-is-external-destination-verification/
resource "aws_route53_record" "txt_dmarc_authorization" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "identitysandbox.gov._report._dmarc.${var.domain}"
  records = ["v=DMARC1"]
  ttl     = "3600"
  type    = "TXT"
  zone_id = aws_route53_zone.primary.zone_id
}

# Add a record under login.gov saying it's OK to send reports for
# connect.gov to login.gov.
# https://space.dmarcian.com/what-is-external-destination-verification/
resource "aws_route53_record" "txt_dmarc_authorization_connect_gov" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "connect.gov._report._dmarc.${var.domain}"
  records = ["v=DMARC1"]
  ttl     = "3600"
  type    = "TXT"
  zone_id = aws_route53_zone.primary.zone_id
}

# TODO: Add this record once we upgrade to a version of terraform that can
# handle TXT records > 255 characters long, whether split with escaped quotes
# or not.
# This record is only used for the prod login.gov G Suite DKIM signing.
#resource "aws_route53_record" "google_dkim_txt" {
#    name = "google._domainkey.${var.domain}"
#    records = ["v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkcuOOdgaWfHIKM1ILlzPOHBPJKLxU9+1+ufIprNdjrD+QQ6/uJtc/tP5s1MUwYU/fld2Y1QwXC5JHdE6JXP31XwCtvbfIwn/Dr/EaRB3PomOp0SNbTtFMmvuxPF87HidvzDH3cWXcmyjMx6XU1i9O3nBs66Z+8i4gfh/PZdjJs6wcNp9urJjCo23KYzbiNAn7FJjbD4g3NucMvkBXHIsOMLvb7WzIekpxL2bjz6XlDfK1t4VTLv4IqIlLMfhYGwwaWPhgyra7qezYkp6a2XSoLWxPWRbfb1bNmVUJ7vBeB6NdFnr9n/7TqbhDVEo9/XyO1MIsuNTTZuhurlZqoXx0QIDAQAB"]
#    ttl = "900"
#    type = "TXT"
#    zone_id = "${aws_route53_zone.primary.zone_id}"
#}

resource "aws_route53_record" "mail_in_txt" {
  name    = "mail.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "TXT"
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "mail_in_mx" {
  name    = "mail.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "MX"
  records = ["10 feedback-smtp.us-west-2.amazonses.com"] # NB us-west-2 only
}

resource "aws_route53_record" "main_dmarc" {
  name    = "_dmarc.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "TXT"
  records = ["v=DMARC1; p=reject; pct=100; fo=1; ri=3600; rua=mailto:gsalogin@rua.agari.com,mailto:dmarc-reports@login.gov,mailto:reports@dmarc.cyber.dhs.gov; ruf=mailto:dmarc-forensics@login.gov"]
}

resource "aws_route53_record" "acme_challenge" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "_acme-challenge.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "120"
  type    = "TXT"
  records = ["g_ybuPyxTGP-JeDhOA-AyjIlJEwsZU5fd0dr7zvpFsg"]
}

resource "aws_route53_record" "acme_challenge_www" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "_acme-challenge.www.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "120"
  type    = "TXT"
  records = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFfs"]
}

resource "aws_route53_record" "hubot_cname1" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "hs1._domainkey.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "CNAME"
  records = ["login-gov.hs01a.dkim.hubspotemail.net."]
}

resource "aws_route53_record" "hubot_cname2" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "hs2._domainkey.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "CNAME"
  records = ["login-gov.hs01b.dkim.hubspotemail.net."]
}

resource "aws_route53_record" "hubot_txt" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "smtpapi._domainkey.${var.domain}"
  zone_id = aws_route53_zone.primary.zone_id
  ttl     = "900"
  type    = "TXT"
  records = ["L1XfURLRizB_sP022sBOoQGaulRl34R9B3xEZxTTFk=rsa; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDPtW5iwpXVPiH5FzJ7Nrl8USzuY9zqqzjE0D1r04xDN6qwziDnmgcFNNfMewVKN2D1O+2J9N14hRprzByFwfQW76yojh54Xu3uSbQ3JP0A7k8o8GutRF8zbFUA8n0ZH2y0cIEjMliXY4W4LwPA7m4q0ObmvSjhd6\"\"3O9d8z1XkUBwIDAQAB"]
}
