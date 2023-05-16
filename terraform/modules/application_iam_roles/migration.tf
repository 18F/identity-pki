resource "aws_iam_role" "migration" {
  name               = "${var.env_name}_migration_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "migration-download-artifacts" {
  name   = "${var.env_name}-migration-download-artifacts"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.download_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "migration-upload-artifacts" {
  name   = "${var.env_name}-migration-upload-artifacts"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.upload_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "migration-idp-secrets" {
  name   = "${var.env_name}-idp-secrets"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "migration-idp-certificates" {
  name   = "${var.env_name}-idp-certificates"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "migration-describe_instances" {
  name   = "${var.env_name}-idp-describe_instances"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "migration-idp-application-secrets" {
  name   = "${var.env_name}-idp-application-secrets"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "migration-cloudwatch-logs" {
  name   = "${var.env_name}-migration-cloudwatch-logs"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "migration-cloudwatch-agent" {
  name   = "${var.env_name}-migration-cloudwatch-agent"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "migration-ssm-access" {
  count  = var.ssm_access_enabled ? 1 : 0
  name   = "${var.env_name}-migration-ssm-access"
  role   = aws_iam_role.migration.id
  policy = var.ssm_policy
}

resource "aws_iam_role_policy" "migration-sns-publish-alerts" {
  name   = "${var.env_name}-idp-sns-publish-alerts"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "migration-ec2-tags" {
  name   = "${var.env_name}-migration-ec2-tags"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.ec2-tags.json
}