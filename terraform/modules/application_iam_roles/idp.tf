# S3 bucket for static assets
locals {
  bucket_name = "login-gov-idp-static-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
  # Need this because prod doesn't have an AutoTerraform role at the moment
  key_management_roles = var.gitlab_enabled ? [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform",
    var.gitlab_env_runner_role_arn
    ] : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
  ]
}

resource "aws_iam_role" "idp" {
  name               = "${var.env_name}_idp_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

resource "aws_iam_role_policy" "idp-download-artifacts" {
  name   = "${var.env_name}-idp-artifacts"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.download_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "idp-secrets" {
  name   = "${var.env_name}-idp-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-transfer-utility" {
  name   = "${var.env_name}-idp-transfer-utility"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

#IDP Role access to S3 bucket and KMS key
resource "aws_iam_role_policy" "idp_doc_capture" {
  name   = "${var.env_name}-idp-doc-capture"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.idp_doc_capture.json
}

# Allow listing CloudHSM clusters
resource "aws_iam_role_policy" "idp-cloudhsm-client" {
  name   = "${var.env_name}-idp-cloudhsm-client"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudhsm:DescribeClusters",
                "cloudhsm:ListTags",
                "cloudhsm:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
EOM

}

resource "aws_iam_role_policy" "idp-certificates" {
  name   = "${var.env_name}-idp-certificates"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "idp-describe_instances" {
  name   = "${var.env_name}-idp-describe_instances"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "idp-application-secrets" {
  name   = "${var.env_name}-idp-application-secrets"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.application_secrets_role_policy.json
}

resource "aws_iam_role_policy" "idp-ses-email" {
  name   = "${var.env_name}-idp-ses-email"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "idp-cloudwatch-logs" {
  name   = "${var.env_name}-idp-cloudwatch-logs"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "idp-cloudwatch-agent" {
  name   = "${var.env_name}-idp-cloudwatch-agent"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

resource "aws_iam_role_policy" "idp-upload-s3-reports" {
  name   = "${var.env_name}-idp-s3-reports"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.put_reports_to_s3.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "idp-ssm-access" {
  count  = var.ssm_access_enabled ? 1 : 0
  name   = "${var.env_name}-idp-ssm-access"
  role   = aws_iam_role.idp.id
  policy = var.ssm_policy
}

# add-on policy permitting access to us-east-1 ssm-logs bucket and SSM KMS key
resource "aws_iam_role_policy" "idp-ssm-access-ue1" {
  count  = var.ssm_access_enabled && var.create_ue1_ssm_policy ? 1 : 0
  name   = "${var.env_name}-idp-ssm-access-ue1"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ssm_kms_key_ue1.json
}

resource "aws_iam_role_policy" "idp-sns-publish-alerts" {
  name   = "${var.env_name}-idp-sns-publish-alerts"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "idp-ec2-tags" {
  name   = "${var.env_name}-idp-ec2-tags"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.ec2-tags.json
}

# Allow assuming cross-account role for Pinpoint APIs. This is in a separate
# account for accounting purposes since it's on a separate contract.
resource "aws_iam_role_policy" "idp-pinpoint-assumerole" {
  name   = "${var.env_name}-idp-pinpoint-assumerole"
  role   = aws_iam_role.idp.id
  policy = <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::${var.identity_sms_aws_account_id}:role/${var.identity_sms_iam_role_name_idp}"
      ]
    }
  ]
}
EOM

}

# Allow publishing traces to X-Ray
resource "aws_iam_role_policy" "idp-xray-publish" {
  name   = "${var.env_name}-idp-xray-publish"
  role   = aws_iam_role.idp.id
  policy = data.aws_iam_policy_document.xray-publish-policy.json
}
