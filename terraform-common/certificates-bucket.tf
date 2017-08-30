variable "certificates_bucket_prefix" {
    description = "Prefix to use when creating the self signed certificates bucket"
    default = "login-gov-internal-certs-test"
}

# NOTE: This is an old bucket, only here to preserve backwards compatibility as
# we roll out the use of the new secrets bucket below to all environments.
# Specifically, as soon as the chef changes in
# https://github.com/18F/identity-devops/pull/574 are deployed to all
# environments we can remove this.
module "certificates_bucket" {
    source = "../terraform-modules/legacy_secrets_bucket"
    bucket_name_prefix = "${var.certificates_bucket_prefix}"
    force_destroy = true
}

module "internal_certificates_bucket" {
    source = "../terraform-modules/secrets_bucket"
    logs_bucket = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    secrets_bucket_type = "internal-certs"
    bucket_name_prefix = "login-gov"
    force_destroy = true
}

output "certificates_bucket" {
    value = "${module.certificates_bucket.bucket_name}"
}
