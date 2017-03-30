provider "aws" {
  region = "${var.region}"
}

resource "aws_route53_record" "a_root" {
  name = "login.gov"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  alias {
    evaluate_target_health = false
    name = "dz4hcx2jg1w8s.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "a_marketing_preview" {
  name = "preview.login.gov"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  alias {
    evaluate_target_health = false
    name = "d1xv3mp8jrwxno.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "a_www" {
  name = "www.login.gov"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  alias {
    evaluate_target_health = false
    name = "dz4hcx2jg1w8s.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "mx_google" {
  name = "login.gov"
  records = [
    "10 aspmx.l.google.com.",
    "20 alt1.aspmx.l.google.com.",
    "20 alt2.aspmx.l.google.com.",
    "30 aspmx2.googlemail.com.",
    "30 aspmx3.googlemail.com.",
    "30 aspmx4.googlemail.com.",
    "30 aspmx5.googlemail.com."
  ]
  ttl = "300"
  type = "TXT"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "txt_google_site_verification" {
  name = "login.gov"
  records = ["google-site-verification=x8WM0Sy9Q4EmkHypuULXjTibNOJmPEoOxDGUmBppws8"]
  ttl = "300"
  type = "TXT"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "txt_google_spf" {
  name = "login.gov"
  records = ["v=spf1 a mx include:gsa.gov ~all"]
  ttl = "300"
  type = "TXT"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "txt_mandrill_dkim" {
  name = "mandrill._domainkey.login.gov"
  records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"]
  ttl = "300"
  type = "TXT"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "txt_mandrill_spf" {
  name = "login.gov"
  records = ["v=spf1 include:spf.mandrillapp.com ?all"]
  ttl = "300"
  type = "TXT"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_zone" "primary" {
  name = "login.gov"
}
