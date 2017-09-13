variable "root_domain" {
    description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "static_cloudfront_name" {
    description = "Static site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}
variable "developers_cloudfront_name" {
    description = "Developers site Cloudfront DNS name, e.g. abcd.cloudfront.net"
}

variable "google_site_verification_txt" {
    description = "Google site verification text to put in TXT record"
    default = ""
}

# TODO remove this after SES migration
variable "mandrill_dkim_record" {
    description = "Mandrill DKIM TXT record content"
}

module "common_dns" {
    source = "../terraform-modules/common_dns/"

    domain = "${var.root_domain}"
    static_cloudfront_name = "${var.static_cloudfront_name}"
    developers_cloudfront_name = "${var.developers_cloudfront_name}"
    google_site_verification_txt = "${var.google_site_verification_txt}"
    mandrill_dkim_record = "${var.mandrill_dkim_record}"
}

output "primary_zone_id" {
    value = "${module.common_dns.primary_zone_id}"
}
output "primary_name_servers" {
    value = ["${module.common_dns.primary_name_servers}"]
}
