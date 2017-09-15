module "app_secrets_bucket" {
    source = "../terraform-modules/secrets_bucket"
    logs_bucket = "${aws_s3_bucket.s3-logs.id}"
    secrets_bucket_type = "app-secrets"
    bucket_name_prefix = "login-gov"
    force_destroy = true
}

output "app_secrets_bucket" {
    value = "${module.app_secrets_bucket.bucket_name}"
}
