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

variable "zendesk_verification_txt" {
  description = "Zendesk verification text to put in TXT record"
  default     = "52b6b9c8a85bbda2"
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
    { name = "", alias_name = var.static_cloudfront_name },
    { name = "www.", alias_name = var.static_cloudfront_name },
    { name = "design.", alias_name = var.design_cloudfront_name },
    { name = "developers.", alias_name = var.developers_cloudfront_name },
  ]

  records = [
    {
      type = "TXT"
      record_set = [
        {
          "name" = "",
          "ttl"  = "900",
          "records" = [
            "google-site-verification=${var.google_site_verification_txt}",
            "v=spf1 include:amazonses.com include:_spf.google.com include:mail.zendesk.com ~all"
          ],
        },
        {
          "name"    = "mail.",
          "ttl"     = "900",
          "records" = ["v=spf1 include:amazonses.com ~all"],
        },
        {
          "name"    = "mail-east.",
          "ttl"     = "3600",
          "records" = ["v=spf1 include:amazonses.com ~all"],
        },
        {
          "name"    = "_dmarc.",
          "ttl"     = "900",
          "records" = ["v=DMARC1; p=reject; pct=100; fo=1; ri=3600; rua=mailto:dmarc-reports@login.gov,mailto:reports@dmarc.cyber.dhs.gov; ruf=mailto:dmarc-forensics@login.gov"],
        },
        {
          "name"    = "zendeskverification.",
          "ttl"     = "900",
          "records" = ["${var.zendesk_verification_txt}"],
        }
      ]
    },
    {
      type = "MX",
      record_set = [
        {
          "name"    = "",
          "ttl"     = "3600",
          "records" = split(",", var.mx_record_map[var.mx_provider]),
        },
        {
          "name"    = "mail.",
          "ttl"     = "900",
          "records" = ["10 feedback-smtp.us-west-2.amazonses.com"] # NB us-west-2 only,
        },
        {
          "name"    = "mail-east.",
          "ttl"     = "3600",
          "records" = ["10 feedback-smtp.us-east-1.amazonses.com"] # NB us-east-1 only,
        },
      ]
    }
  ]

}