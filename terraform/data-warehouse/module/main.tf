locals {
  secrets_bucket      = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  logs_retention_days = (var.env_name == "prod" || var.env_name == "staging" ? "3653" : "30")
}
