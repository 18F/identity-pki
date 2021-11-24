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
  name   = "${var.env_name}-migration-artifacts"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.download_artifacts_role_policy.json
}

resource "aws_iam_role_policy" "migration-upload-artifacts" {
  name   = "${var.env_name}-migration-artifacts"
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

# resource "aws_iam_role_policy" "idp-ses-email" {
#   name   = "${var.env_name}-idp-ses-email"
#   role   = aws_iam_role.migration.id
#   policy = data.aws_iam_policy_document.ses_email_role_policy.json
# }

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

# resource "aws_iam_role_policy" "idp-upload-s3-reports" {
#   name   = "${var.env_name}-idp-s3-reports"
#   role   = aws_iam_role.migration.id
#   policy = data.aws_iam_policy_document.put_reports_to_s3.json
# }

resource "aws_iam_role_policy" "migration-ssm-access" {
  name   = "${var.env_name}-migration-ssm-access"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.ssm_access_role_policy.json
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

# This policy allows writing to the S3 reports bucket
# data "aws_iam_policy_document" "put_reports_to_s3" {
#   statement {
#     sid    = "PutObjectsToReportsS3Bucket"
#     effect = "Allow"
#     actions = [
#       "s3:PutObject",
#     ]
#     resources = [
#       "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
#     ]
#   }
# 
#   # allow listing objects so we can see what we've uploaded
#   statement {
#     sid    = "ListBucket"
#     effect = "Allow"
#     actions = [
#       "s3:ListBucket",
#     ]
#     resources = [
#       "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}",
#     ]
#   }
# }

# Allow assuming cross-account role for Pinpoint APIs. This is in a separate
# account for accounting purposes since it's on a separate contract.
# resource "aws_iam_role_policy" "idp-pinpoint-assumerole" {
#   name   = "${var.env_name}-idp-pinpoint-assumerole"
#   role   = aws_iam_role.idp.id
#   policy = <<EOM
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "sts:AssumeRole",
#       "Resource": [
#         "arn:aws:iam::${var.identity_sms_aws_account_id}:role/${var.identity_sms_iam_role_name_idp}"
#       ]
#     }
#   ]
# }
# EOM
# 
# }
