data "aws_s3_bucket" "secrets" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.id}-${var.region}"
}

data "aws_availability_zones" "available" {
}

data "aws_caller_identity" "current" {
}

data "github_ip_ranges" "meta" {
}

data "aws_s3_bucket" "access_logging" {
  bucket = "login-gov.s3-access-logs.${data.aws_caller_identity.current.id}-${var.region}"
}
