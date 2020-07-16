# -- Variables --

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

variable "acme_partners_cloudfront_name" {
  description = "Partners site Cloudfront DNS name, e.g. abcd.cloudfront.net"
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

variable "prod_records" {
  description = "Additional Route53 mappings for the prod login.gov account."
  type        = list(any)
}

# -- Locals --

locals {

  cloudfront_aliases = [
    { name = "",           alias_name = var.static_cloudfront_name     },
    { name = "www.",        alias_name = var.static_cloudfront_name     },
    { name = "design.",     alias_name = var.design_cloudfront_name     },
    { name = "developers.", alias_name = var.developers_cloudfront_name },
  ]

  records = [
    {
      type = "TXT"
      record_set = [
        {
          "name" = "",
          "ttl" = "900",
          "records" = ["google-site-verification=${var.google_site_verification_txt}", "v=spf1 include:amazonses.com include:_spf.google.com ~all"],
        },
        {
          "name" = "mail.",
          "ttl" = "900",
          "records" = ["v=spf1 include:amazonses.com ~all"],
        },
        {
          "name" = "mail-east.",
          "ttl" = "3600",
          "records" = ["v=spf1 include:amazonses.com ~all"],
        },
        {
          "name" = "_dmarc.",
          "ttl" = "900",
          "records" = ["v=DMARC1; p=reject; pct=100; fo=1; ri=3600; rua=mailto:gsalogin@rua.agari.com,mailto:dmarc-reports@login.gov,mailto:reports@dmarc.cyber.dhs.gov; ruf=mailto:dmarc-forensics@login.gov"],
        }
      ]
    },
    {
      type = "MX",
      record_set = [
        {
          "name" = "",
          "ttl" = "3600",
          "records" = split(",", var.mx_record_map[var.mx_provider]),
        },
        {
          "name" = "mail.",
          "ttl" = "900",
          "records" = ["10 feedback-smtp.us-west-2.amazonses.com"] # NB us-west-2 only,
        },
        {
          "name" = "mail-east.",
          "ttl" = "3600",
          "records" = ["10 feedback-smtp.us-east-1.amazonses.com"] # NB us-east-1 only,
        },
      ]
    }
  ]

}

# -- Resources --

resource "aws_route53_zone" "primary" {
  # domain, ensuring it has a trailing "."
  name = replace(var.domain, "/\\.?$/", ".")
}

resource "aws_route53_record" "a" {
  for_each = {
    for a in local.cloudfront_aliases :
      a.name == "" ? "a_root" : "a_${trimsuffix(a.name,".")}" => a
    }

  name    = join("", [each.value.name, var.domain])
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = each.value.alias_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "record" {
  for_each = { for n in flatten([
      for entry in flatten([local.records, var.prod_records]) : [
        for r in entry.record_set : {
          type = entry.type,
          name = r.name,
          ttl = r.ttl,
          records = r.records
        }
      ]
    ]) : n.name == "" ? "${n.type}_main" : "${n.type}_${trimsuffix(n.name,".")}" => n }

  name    = join("", [each.value.name, var.domain])
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
  zone_id = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "acme_partners" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "partners.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.acme_partners_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

# -- Outputs --

output "primary_zone_id" {
  description = "ID for the primary Route53 zone."
  value       = aws_route53_zone.primary.zone_id
}

output "primary_domain" {
  description = "DNS domain to use as the root domain, e.g. 'login.gov.'"
  value       = var.domain
}

output "primary_name_servers" {
  description = "Nameservers within the primary Route53 zone."
  value       = [
    for num in range(4) : element(aws_route53_zone.primary.name_servers, num)
  ]
}