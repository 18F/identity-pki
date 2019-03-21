variable "root_domain" {
    description = "DNS domain to use as the root domain, e.g. login.gov"
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


variable "google_site_verification_txt" {
    description = "Google site verification text to put in TXT record"
    default = ""
}

variable "mx_provider" {
    description = "Name of the MX provider to set up records for, see common_dns module"
}

variable "sandbox_ses_inbound_enabled" {
    description = "Whether to enable identitysandbox.gov style SES inbound processing"
    default = 0
}

module "common_dns" {
    source = "../terraform-modules/common_dns/"

    domain = "${var.root_domain}"
    static_cloudfront_name = "${var.static_cloudfront_name}"
    design_cloudfront_name = "${var.design_cloudfront_name}"
    developers_cloudfront_name = "${var.developers_cloudfront_name}"
    google_site_verification_txt = "${var.google_site_verification_txt}"

    mx_provider = "${var.mx_provider}"
}

output "primary_zone_id" {
    value = "${module.common_dns.primary_zone_id}"
}
output "primary_name_servers" {
    value = ["${module.common_dns.primary_name_servers}"]
}

module "sandbox_ses" {
    source = "../terraform-modules/sandbox_ses/"

    domain = "${var.root_domain}"

    enabled = "${var.sandbox_ses_inbound_enabled}"
    email_bucket = "${aws_s3_bucket.s3-email.bucket}"
}
