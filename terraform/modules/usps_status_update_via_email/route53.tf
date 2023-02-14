resource "aws_route53_zone" "usps_zone" {
  name = "usps.${var.env_name}.${var.root_domain}"
}

resource "aws_route53_record" "usps_ses_domain" {
  zone_id = var.route53_id
  name    = "usps.${var.env_name}.${var.root_domain}"
  type    = "NS"
  ttl     = "600"
  records = aws_route53_zone.usps_zone.name_servers
}

resource "aws_route53_record" "usps_ses_verify" {
  zone_id = aws_route53_zone.usps_zone.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.usps.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.usps.verification_token]
}

resource "aws_route53_record" "usps_ses_recieve_mx" {
  zone_id = aws_route53_zone.usps_zone.zone_id
  name    = aws_route53_zone.usps_zone.name
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}
