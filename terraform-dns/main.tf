provider "aws" {
  region = "${var.region}"
}

resource "aws_route53_zone" "primary" {
  name = "login.gov"
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

resource "aws_route53_record" "mx" {
  name = "login.gov"
  records = ["10 30288227.in1.mandrillapp.com", "20 30288227.in2.mandrillapp.com"]
  ttl = "300"
  type = "MX"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}


# hardcode in www
resource "aws_route53_record" "a_root" {
  name = "login.gov"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  alias {
    name = "dz4hcx2jg1w8s.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "c_www" {
  name = "www.login.gov"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
  alias {
    name = "dz4hcx2jg1w8s.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# hardcode in old chef
resource "aws_route53_record" "a_chef" {
  name = "chef.login.gov"
  records = ["35.162.6.23"]
  ttl = "300"
  type = "A"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}

resource "aws_route53_record" "c_marketing_preview" {
  name = "preview.login.gov"
  records = ["d1xv3mp8jrwxno.cloudfront.net"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.primary.zone_id}"
}
