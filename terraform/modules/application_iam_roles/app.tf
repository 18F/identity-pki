resource "aws_iam_role" "app" {
  count              = var.apps_enabled
  name               = "${var.env_name}_app_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "app-secrets-manager" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-secrets-manager"
  role   = aws_iam_role.app[count.index].id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:List*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:Get*",
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:global/common/*",
                "arn:aws:secretsmanager:*:*:secret:global/app/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/app/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/sp-oidc-sinatra/*"
            ]
        }
    ]
}
EOM

}

resource "aws_iam_role_policy" "app-s3-logos-access" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-s3-logos-access"
  role   = aws_iam_role.app[count.index].id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:GetObject",
                "s3:ListObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
                "arn:aws:s3:::login-gov-partner-logos-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
            ]
        }
    ]
}
EOM
}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "app-xray-publish" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-xray-publish"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}

# These policies are all duplicated from base-permissions

resource "aws_iam_role_policy" "app-secrets" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-secrets"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "app-certificates" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-certificates"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "app-describe_instances" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-describe_instances"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "app-ses-email" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-ses-email"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "app-cloudwatch-logs" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-cloudwatch-logs"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "app-cloudwatch-agent" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-cloudwatch-agent"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "app-ssm-access" {
  count  = var.apps_enabled == 1 && var.ssm_access_enabled ? 1 : 0
  name   = "${var.env_name}-app-ssm-access"
  role   = aws_iam_role.app[count.index].id
  policy = var.ssm_policy
}

# add-on policy permitting access to us-east-1 ssm-logs bucket and SSM KMS key
resource "aws_iam_role_policy" "app-ssm-access-ue1" {
  count  = var.apps_enabled == 1 && var.ssm_access_enabled && var.create_ue1_ssm_policy ? 1 : 0
  name   = "${var.env_name}-app-ssm-access-ue1"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.ssm_kms_key_ue1.json
}

resource "aws_iam_role_policy" "app-sns-publish-alerts" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-sns-publish-alerts"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "app-transfer-utility" {
  count  = var.apps_enabled
  name   = "${var.env_name}-app-transfer-utility"
  role   = aws_iam_role.app[count.index].id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

# </end> base-permissions policies