resource "aws_iam_role" "migration" {
  name               = "${var.env_name}_migration_iam_role"
  description        = "Enables multiple permissions needed for the identity-reporting-rails application to run on the analytics migration host."
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "migration-analytics-secrets" {
  name   = "${var.env_name}-analytics-secrets"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "migration-analytics-certificates" {
  name   = "${var.env_name}-analytics-certificates"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "migration-describe_instances" {
  name   = "${var.env_name}-analytics-describe_instances"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "migration-analytics-application-secrets" {
  name   = "${var.env_name}-analytics-application-secrets"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "migration-analytics-application-secrets-secrets-manager" {
  name   = "${var.env_name}-analytics-application-secrets-secrets-manager"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.application_secrets_secrets_manager_role_policy.json
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
  name   = "${var.env_name}-migration-ssm-access"
  role   = aws_iam_role.migration.id
  policy = module.ssm.ssm_access_role_policy
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
