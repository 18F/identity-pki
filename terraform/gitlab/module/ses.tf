resource "aws_ses_domain_identity" "gitlab" {
  domain = "gitlab.${var.env_name}.${var.root_domain}"
}

resource "aws_ses_domain_dkim" "gitlab" {
  domain = aws_ses_domain_identity.gitlab.domain
}

resource "aws_route53_record" "gitlab_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.gitlab.zone_id
  name    = "_amazonses.gitlab.${var.env_name}.${var.root_domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.gitlab.verification_token]
}


resource "aws_route53_record" "gitlab_amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.gitlab.zone_id
  name    = "${element(aws_ses_domain_dkim.gitlab.dkim_tokens, count.index)}._domainkey.gitlab.${var.env_name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.gitlab.dkim_tokens, count.index)}.dkim.amazonses.com"]
}
