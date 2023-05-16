resource "aws_iam_role" "pivcac" {
  name               = "${var.env_name}_pivcac_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "pivcac_update_route53" {
  name   = "${var.env_name}-pivcac_update_route53"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.pivcac_route53_modification.json
}

resource "aws_iam_role_policy" "pivcac-secrets" {
  name   = "${var.env_name}-pivcac-secrets"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-certificates" {
  name   = "${var.env_name}-pivcac-certificates"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-describe_instances" {
  name   = "${var.env_name}-pivcac-describe_instances"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "pivcac-cloudwatch-logs" {
  name   = "${var.env_name}-pivcac-cloudwatch-logs"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "pivcac-cloudwatch-agent" {
  name   = "${var.env_name}-pivcac-cloudwatch-agent"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "pivcac-ssm-access" {
  count  = var.ssm_access_enabled ? 1 : 0
  name   = "${var.env_name}-pivcac-ssm-access"
  role   = aws_iam_role.pivcac.id
  policy = var.ssm_policy
}

resource "aws_iam_role_policy" "pivcac-sns-publish-alerts" {
  name   = "${var.env_name}-pivcac-sns-publish-alerts"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "pivcac-xray-publish" {
  name   = "${var.env_name}-pivcac-xray-publish"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

resource "aws_iam_role_policy" "pivcac-transfer-utility" {
  name   = "${var.env_name}-pivcac-transfer-utility"
  role   = aws_iam_role.pivcac.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}