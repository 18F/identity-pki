# Set up an internal dns zone that we can use for service discovery

resource "aws_route53_zone" "internal" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "login.gov.internal"
  vpc {
    vpc_id = aws_vpc.default.id
  }
}

resource "aws_route53_zone" "internal-reverse" {
  comment = "${var.name}-zone-${var.env_name}"
  name    = "16.172.in-addr.arpa"
  vpc {
    vpc_id = aws_vpc.default.id
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

# Turn on DNSSec Validation
resource "aws_route53_resolver_dnssec_config" "vpc" {
  resource_id = aws_vpc.default.id
}

# Use per-environment internal resolver for nice resolver logging
resource "aws_route53_resolver_query_log_config" "internal" {
  name            = "${var.name}-vpc-${var.env_name}"
  destination_arn = aws_cloudwatch_log_group.dns_query_log.arn
}

resource "aws_route53_resolver_query_log_config_association" "internal" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.internal.id
  resource_id                  = aws_vpc.default.id
}
