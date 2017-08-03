variable "certificates_bucket_prefix" {
    description = "Prefix to use when creating the self signed certificates bucket"
    default = "login-gov-internal-certs-test"
}

module "certificates_bucket" {
    source = "../terraform-modules/secrets_bucket"
    bucket_name_prefix = "${var.certificates_bucket_prefix}"
    force_destroy = true
}

output "certificates_bucket" {
    value = "${module.certificates_bucket.bucket_name}"
}
