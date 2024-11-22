# Set up an internal dns zone that we can use for service discovery

resource "aws_route53_zone" "internal" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "login.gov.internal"
  vpc {
    vpc_id = aws_vpc.analytics_vpc.id
  }
}

resource "aws_route53_zone" "internal-reverse" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "16.172.in-addr.arpa"
  vpc {
    vpc_id = aws_vpc.analytics_vpc.id
  }
}

resource "aws_route53_record" "internal-ns" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.internal.zone_id
  name            = "login.gov.internal"
  type            = "NS"
  ttl             = "30"
  records         = aws_route53_zone.internal.name_servers
}
