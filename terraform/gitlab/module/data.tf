data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.id}-${var.region}"
}

data "aws_vpc_endpoint_service" "email-smtp" {
  service      = "email-smtp"
  service_type = "Interface"
}
