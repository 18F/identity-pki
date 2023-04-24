# Grab the hosted zone ID for our domain
data "aws_route53_zone" "selected" {
  name = var.dnszone
}

# Create our wildcard certificate
resource "aws_acm_certificate" "wildcard" {
  domain_name       = "*.${var.dnszone}"
  validation_method = "DNS"

  tags = {
    Name      = "${var.cluster_name}-wildcard"
    Terraform = "true"
  }
}

# Validate our wildcard certificate
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.selected.zone_id
  records = [each.value.record]
  ttl     = 60
}