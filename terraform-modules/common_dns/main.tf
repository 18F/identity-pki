variable "domain" {
    description = "DNS domain to use as the root domain, e.g. 'login.gov.'"
}

variable "static_cloudfront_name" {
    description = "Static site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}
variable "developers_cloudfront_name" {
    description = "Developers site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}
variable "cloudfront_zone_id" {
    description = "Static site Cloudfront Zone ID, e.g. ZABCDEFG1234"
    default = "Z2FDTNDATAQYW2" # Zone ID for all cloudfront sites?
}

variable "google_site_verification_txt" {
    description = "Google site verification text to put in TXT record"
    default = ""
}

resource "aws_route53_zone" "primary" {
    # domain, ensuring it has a trailing "."
    name = "${replace(var.domain, "/\\.?$/", ".")}"
}

output "primary_zone_id" {
    value = "${aws_route53_zone.primary.zone_id}"
}
output "primary_domain" {
    value = "${var.domain}"
}
output "primary_name_servers" {
    value = [
        "${aws_route53_zone.primary.name_servers.0}",
        "${aws_route53_zone.primary.name_servers.1}",
        "${aws_route53_zone.primary.name_servers.2}",
        "${aws_route53_zone.primary.name_servers.3}"
    ]
}


resource "aws_route53_record" "a_root" {
    name = "${var.domain}"
    type = "A"
    zone_id = "${aws_route53_zone.primary.zone_id}"
    alias {
        evaluate_target_health = false
        name = "${var.static_cloudfront_name}"
        zone_id = "${var.cloudfront_zone_id}"
    }
}

resource "aws_route53_record" "a_www" {
    name = "www.${var.domain}"
    type = "A"
    zone_id = "${aws_route53_zone.primary.zone_id}"
    alias {
        evaluate_target_health = false
        name = "${var.static_cloudfront_name}"
        zone_id = "${var.cloudfront_zone_id}"
    }
}

resource "aws_route53_record" "a_developers" {
    name = "developers.${var.domain}"
    type = "A"
    zone_id = "${aws_route53_zone.primary.zone_id}"
    alias {
        evaluate_target_health = false
        name = "${var.developers_cloudfront_name}"
        zone_id = "${var.cloudfront_zone_id}"
    }
}


resource "aws_route53_record" "mx_google" {
    name = "${var.domain}"
    records = [
        "10 aspmx.l.google.com.",
        "20 alt1.aspmx.l.google.com.",
        "20 alt2.aspmx.l.google.com.",
        "30 aspmx2.googlemail.com.",
        "30 aspmx3.googlemail.com.",
        "30 aspmx4.googlemail.com.",
        "30 aspmx5.googlemail.com."
    ]
    ttl = "3600"
    type = "MX"
    zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "txt" {
    name = "${var.domain}"
    records = ["google-site-verification=${var.google_site_verification_txt}", "v=spf1 mx include:spf_sa.gsa.gov ~all"]
    ttl = "900"
    type = "TXT"
    zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "mail_in_txt" {
    name = "mail.${var.domain}"
    zone_id = "${aws_route53_zone.primary.zone_id}"
    ttl = "900"
    type = "TXT"
    records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "mail_in_mx" {
    name = "mail.${var.domain}"
    zone_id = "${aws_route53_zone.primary.zone_id}"
    ttl = "900"
    type = "MX"
    records = ["10 feedback-smtp.us-west-2.amazonses.com"] # NB us-west-2 only
}
