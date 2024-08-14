resource "aws_iam_role" "analytics" {
  name               = "${var.env_name}_analytics_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "analytics-secrets" {
  name   = "${var.env_name}-analytics-secrets"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "analytics-transfer-utility" {
  name   = "${var.env_name}-analytics-transfer-utility"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

resource "aws_iam_role_policy" "analytics-certificates" {
  name   = "${var.env_name}-analytics-certificates"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "analytics-describe_instances" {
  name   = "${var.env_name}-analytics-describe_instances"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "analytics-application-secrets" {
  name   = "${var.env_name}-analytics-application-secrets"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "analytics-application-secrets-secrets-manager" {
  name   = "${var.env_name}-analytics-application-secrets-secrets-manager"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.application_secrets_secrets_manager_role_policy.json
}

resource "aws_iam_role_policy" "analytics-cloudwatch-logs" {
  name   = "${var.env_name}-analytics-cloudwatch-logs"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "analytics_redshift_user_sync" {
  name   = "${var.env_name}-analytics-redshift-user-sync"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.redshift_user_sync.json
}

resource "aws_iam_role_policy" "analytics-cloudwatch-agent" {
  name   = "${var.env_name}-analytics-cloudwatch-agent"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "analytics-ssm-access" {
  name   = "${var.env_name}-analytics-ssm-access"
  role   = aws_iam_role.analytics.id
  policy = module.ssm.ssm_access_role_policy
}

resource "aws_iam_role_policy" "analytics-sns-publish-alerts" {
  name   = "${var.env_name}-analytics-sns-publish-alerts"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "analytics-ec2-tags" {
  name   = "${var.env_name}-analytics-ec2-tags"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.ec2-tags.json
}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "analytics-xray-publish" {
  name   = "${var.env_name}-analytics-xray-publish"
  role   = aws_iam_role.analytics.id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

resource "aws_iam_instance_profile" "analytics" {
  name_prefix = "${var.env_name}_analytics_instance_profile"
  role        = aws_iam_role.analytics.name
}

