# IAM instance profile using the application secrets role
resource "aws_iam_instance_profile" "application-secrets" {
  name = "${var.env_name}-application-secrets"
  role = module.application_iam_roles.application_secrets_iam_role_name
}

