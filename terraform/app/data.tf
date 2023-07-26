data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.id}-${var.region}"
}

data "aws_s3_bucket" "app_secrets" {
  bucket = "login-gov.app-secrets.${data.aws_caller_identity.current.id}-${var.region}"
}