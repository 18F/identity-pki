resource "aws_iam_role" "obproxy" {
  name               = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "obproxy-secrets" {
  name   = "${var.env_name}-obproxy-secrets"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-certificates" {
  name   = "${var.env_name}-obproxy-certificates"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-describe_instances" {
  name   = "${var.env_name}-obproxy-describe_instances"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "obproxy-cloudwatch-logs" {
  name   = "${var.env_name}-obproxy-cloudwatch-logs"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "obproxy-cloudwatch-agent" {
  name   = "${var.env_name}-obproxy-cloudwatch-agent"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "obproxy-auto-eip" {
  name   = "${var.env_name}-obproxy-auto-eip"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.auto_eip_policy.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "obproxy-ssm-access" {
  count  = var.ssm_policy != "" ? 1 : 0
  name   = "${var.env_name}-obproxy-ssm-access"
  role   = aws_iam_role.obproxy.id
  policy = var.ssm_policy
}

resource "aws_iam_role_policy" "obproxy-sns-publish-alerts" {
  name   = "${var.env_name}-obproxy-sns-publish-alerts"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "obproxy-transfer-utility" {
  name   = "${var.env_name}-obproxy-transfer-utility"
  role   = aws_iam_role.obproxy.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}
