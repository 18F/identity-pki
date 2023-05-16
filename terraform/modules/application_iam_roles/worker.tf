resource "aws_iam_role" "worker" {
  name               = "${var.env_name}_worker_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

#Worker Role access to S3 bucket and KMS key
resource "aws_iam_role_policy" "worker_doc_capture" {
  name   = "${var.env_name}-worker-doc-capture"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.idp_doc_capture.json
}

resource "aws_iam_role_policy" "worker-download-artifacts" {
  name   = "${var.env_name}-worker-artifacts"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.download_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "worker-secrets" {
  name   = "${var.env_name}-worker-secrets"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.secrets_role_policy.json
}

resource "aws_iam_role_policy" "worker-certificates" {
  name   = "${var.env_name}-worker-certificates"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.certificates_role_policy.json
}

resource "aws_iam_role_policy" "worker-describe_instances" {
  name   = "${var.env_name}-worker-describe_instances"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.describe_instances_role_policy.json
}

resource "aws_iam_role_policy" "worker-ses-email" {
  name   = "${var.env_name}-worker-ses-email"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.ses_email_role_policy.json
}

resource "aws_iam_role_policy" "worker-cloudwatch-logs" {
  name   = "${var.env_name}-worker-cloudwatch-logs"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.cloudwatch-logs.json
}

resource "aws_iam_role_policy" "worker-cloudwatch-agent" {
  name   = "${var.env_name}-worker-cloudwatch-agent"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.cloudwatch-agent.json
}

# Conditionally create ssm policy, for backwards compatibility with non kubernetes environments
resource "aws_iam_role_policy" "worker-ssm-access" {
  count  = var.ssm_access_enabled ? 1 : 0
  name   = "${var.env_name}-worker-ssm-access"
  role   = aws_iam_role.worker.id
  policy = var.ssm_policy
}

resource "aws_iam_role_policy" "worker-sns-publish-alerts" {
  name   = "${var.env_name}-worker-sns-publish-alerts"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.sns-publish-alerts-policy.json
}

resource "aws_iam_role_policy" "worker-upload-s3-reports" {
  name   = "${var.env_name}-worker-s3-reports"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.put_reports_to_s3.json
}

resource "aws_iam_role_policy" "worker-transfer-utility" {
  name   = "${var.env_name}-worker-transfer-utility"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.transfer_utility_policy.json
}

resource "aws_iam_role_policy" "worker-usps-queue" {
  count  = var.enable_usps_status_updates ? 1 : 0
  name   = "${var.env_name}-worker-usps-queue"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.usps_queue_policy[0].json
}


# Allow assuming cross-account role for Pinpoint APIs. This is in a separate
# account for accounting purposes since it's on a separate contract.
resource "aws_iam_role_policy" "worker-pinpoint-assumerole" {
  name   = "${var.env_name}-worker-pinpoint-assumerole"
  role   = aws_iam_role.worker.id
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