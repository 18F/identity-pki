# Very similar to terraform/app/idp.tf

resource "aws_iam_instance_profile" "migration" {
  name = "${var.env_name}_migration_instance_profile"
  role = aws_iam_role.migration.name
}

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

resource "aws_iam_role_policy" "migration-idp-secrets-manager" {
  name   = "${var.env_name}-idp-secrets-manager"
  role   = aws_iam_role.migration.id
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
                "arn:aws:secretsmanager:*:*:secret:global/idp/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/common/*",
                "arn:aws:secretsmanager:*:*:secret:${var.env_name}/idp/*"
            ]
        }
    ]
}
EOM

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
