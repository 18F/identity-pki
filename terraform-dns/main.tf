provider "aws" {
  access_key = "${var.access_key_18f_ent}"
  secret_key = "${var.secret_key_18f_ent}"
  region = "${var.region}"
  profile = "18f-ent"
}

provider "aws" {
  access_key = "${var.access_key}"
  alias = "18f-sandbox"
  profile = "18f-sandbox"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_route53_record" "txt_mandrill_dkim" {
  name = "mandrill._domainkey.login.gov"
  records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"]
  ttl = "300"
  type = "TXT"
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "txt_mandrill_spf" {
  name = "login.gov"
  records = ["v=spf1 include:spf.mandrillapp.com ?all"]
  ttl = "300"
  type = "TXT"
  zone_id = "${var.zone_id}"
}
