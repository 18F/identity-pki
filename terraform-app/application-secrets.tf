# Roles and policies to allow the applications to download their own secrets.

data "aws_iam_policy_document" "application_secrets_role_policy" {
  statement {
    sid    = "AllowApplicationSecretsBucket${var.env_name}"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${var.app_secrets_bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}/${var.env_name}/",
      "arn:aws:s3:::${var.app_secrets_bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}/${var.env_name}/*",
    ]
  }
}

# Role that allows for download of application secrets from the application
# secrets.
#
# This allows the application team to manage their own secrets, and decouples
# config changes there from the infrastructure.
resource "aws_iam_role" "application-secrets" {
  name               = "${var.env_name}-application-secrets"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

# Role policy that associates it with the application_secrets_role_policy
resource "aws_iam_role_policy" "application-secrets" {
  name   = "${var.env_name}-application-secrets"
  role   = aws_iam_role.application-secrets.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

# IAM instance profile using the application secrets role
resource "aws_iam_instance_profile" "application-secrets" {
  name = "${var.env_name}-application-secrets"
  role = aws_iam_role.application-secrets.name
}

