# cert for gitlab, attached to the lb
resource "aws_acm_certificate" "gitlab" {
  domain_name       = "gitlab.${var.env_name}.${var.root_domain}"
  validation_method = "DNS"

  tags = {
    Name = "gitlab${var.env_name}.${var.root_domain}"
  }
}

data "aws_route53_zone" "gitlab" {
  name = var.root_domain
}

resource "aws_route53_record" "gitlab-validation" {
  for_each = {
    for dvo in aws_acm_certificate.gitlab.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.gitlab.zone_id
}

resource "aws_acm_certificate_validation" "gitlab" {
  certificate_arn         = aws_acm_certificate.gitlab.arn
  validation_record_fqdns = [for record in aws_route53_record.gitlab-validation : record.fqdn]
}
