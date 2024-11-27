data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "pivcac_route53_modification" {
  statement {
    sid    = "AllowPIVCACCertbotToDNS01"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "AllowPIVCACCertbotToDNS02"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.pivcac_route53_zone_id}",
    ]
  }
}

# This policy can be used to allow the EC2 service to assume the role.
data "aws_iam_policy_document" "assume_role_from_vpc" {
  dynamic "statement" {
    for_each = var.eks_oidc_provider_arn == null ? [1] : []
    content {
      sid = "allowVPC"
      actions = [
        "sts:AssumeRole",
      ]
      principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.eks_oidc_provider_arn != null ? [1] : []
    content {
      sid = "AllowAssumeRoleFromOIDC"
      actions = [
        "sts:AssumeRoleWithWebIdentity",
      ]
      principals {
        type        = "Federated"
        identifiers = [var.eks_oidc_provider_arn]
      }
      condition {
        test     = "StringLike"
        variable = "${var.eks_oidc_provider}:sub"
        values   = [for sa in var.service_accounts : "system:serviceaccount:${sa}"]
      }
      condition {
        test     = "StringEquals"
        variable = "${var.eks_oidc_provider}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }
}

data "aws_iam_policy_document" "idp_doc_capture" {
  statement {
    sid    = "KMSDocCaptureKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = [
      var.idp_doc_capture_kms_arn,
    ]
  }

  statement {
    sid    = "S3DocCaptureUploadAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      var.idp_doc_capture_arn,
      "${var.idp_doc_capture_arn}/*"
    ]
  }
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
            "Action": "secretsmanager:GetSecretValue",
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

resource "aws_iam_role_policy" "idp-secrets-manager" {
  name   = "${var.env_name}-idp-secrets-manager"
  role   = aws_iam_role.idp.id
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
            "Action": "secretsmanager:GetSecretValue",
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

resource "aws_iam_role_policy" "worker-idp-secrets-manager" {
  name   = "${var.env_name}-idp-secrets-manager"
  role   = aws_iam_role.worker.id
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
            "Action": "secretsmanager:GetSecretValue",
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

# This policy allows writing to the S3 reports bucket
data "aws_iam_policy_document" "put_reports_to_s3" {
  statement {
    sid    = "PutObjectsToReportsS3Bucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
    ]
  }

  # allow listing objects so we can see what we've uploaded
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.reports.${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }
}

# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # TODO: login-gov-secrets-test and login-gov-secrets are deprecated
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
    ]
  }

  # allow ls to work
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # Allow notifying ASG lifecycle hooks. This isn't a great place for this
  # permission since not actually related, but it's useful to put here because
  # all of our ASG instances need it.
  statement {
    sid    = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*",
    ]
  }
}

data "aws_iam_policy_document" "public_reporting_data_policy" {
  # IdP and Worker instances can manage content
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.idp.arn,
        aws_iam_role.worker.arn,
      ]
    }
    resources = [
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}",
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }

  # Cloudfront access for GET on specific item.  Since we are using the
  # S3 origin the call from CloudFront to S3 uses the S3 API so we do
  # not want to expose permissions like List.
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_oai_iam_arn]
    }
    resources = [
      "arn:aws:s3:::login-gov-pubdata-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}/*"
    ]
  }
}

data "aws_iam_policy_document" "glue-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "describe_instances_role_policy" {
  statement {
    sid    = "AllowDescribeInstancesIntegrationTest"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*",
    ]
  }
}

# This policy can allow any node/host to access the bucket containing our self
# signed certificates (for service registration and discovery)
data "aws_iam_policy_document" "certificates_role_policy" {
  statement {
    sid    = "AllowCertificatesBucketIntegrationTest"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
    ]
  }
}

# Roles and policies to allow the applications to download their own secrets.

data "aws_iam_policy_document" "application_secrets_role_policy" {
  statement {
    sid    = "AllowApplicationSecretsBucket${var.env_name}"
    effect = "Allow"
    actions = [
      # TODO: ROLE-AUDIT-XXX https://github.com/18F/identity-devops/issues/1563
      # pretty sure this should only grant read, not s3:*
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${var.app_secrets_bucket_name_prefix}-*-${data.aws_caller_identity.current.account_id}/${var.env_name}/",
      "arn:aws:s3:::${var.app_secrets_bucket_name_prefix}-*-${data.aws_caller_identity.current.account_id}/${var.env_name}/*",
    ]
  }
}

#This policy is for writing log files to CloudWatch
data "aws_iam_policy_document" "cloudwatch-logs" {
  statement {
    sid = "allowCloudWatch"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

#This policy allows the CloudWatch agent to put metrics.
#Also requires the cloudwatch-logs policy
#Based on the AWS managed policy CloudWatchAgentServerPolicy
data "aws_iam_policy_document" "cloudwatch-agent" {
  statement {
    sid = "allowCloudWatchAgent"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
    ]
    resources = [
      "*",
    ]
  }
}

# Allows IDP worker hosts to query cloudwatch insights
data "aws_iam_policy_document" "worker-cloudwatch-insights" {
  statement {
    sid = "AllowQueryAndLogGroupAccess"
    actions = [
      "logs:StartQuery",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.env_name}_/srv/idp/shared/log/events.log:*",
    ]
  }

  statement {
    sid = "AllowGetLogEvents"
    actions = [
      "logs:GetLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.env_name}_/srv/idp/shared/log/events.log:log-stream:*",
    ]
  }

  statement {
    sid = "AllowGetAndStopQuery"
    actions = [
      "logs:GetQueryResults",
      "logs:StopQuery",
    ]
    resources = [
      "*",
    ]
  }

}

# Allow publishing to SNS topics used for alerting
#This policy is for writing log files to CloudWatch
data "aws_iam_policy_document" "sns-publish-alerts-policy" {
  statement {
    sid = "allowSNSPublish"
    actions = [
      "SNS:Publish",
    ]
    resources = [
      var.slack_events_sns_hook_arn,
      var.slack_events_sns_hook_arn_use1,
    ]
  }
}

# Allow publishing traces to X-Ray
data "aws_iam_policy_document" "xray-publish-policy" {
  statement {
    sid = "allowXRayPublish"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]
    resources = [
      "*",
    ]
  }
}

# Allow Tagging EC2 instances
data "aws_iam_policy_document" "ec2-tags" {
  statement {
    sid = "allowEC2Tags"
    actions = [
      "ec2:DescribeTags",
      "ec2:CreateTags",
    ]

    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/domain"
      values = [
        "${var.env_name}.${var.root_domain}"
      ]
    }
  }
}

# Roles and policies relevant to Amazon Simple Email Service
#
# See https://docs.aws.amazon.com/ses/latest/DeveloperGuide/control-user-access.html
#
# Refer to top comment in secrets.tf  to understand how IAM roles, policies,
# and instance profile work.

# Allow SES to send emails from the idp + worker hosts
data "aws_iam_policy_document" "ses_email_role_policy" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendRawEmail",
      "ses:SendEmail",
    ]
    resources = [
      "*",
    ]
  }
}

locals {
  transfer_bucket = join("-", [
    "arn:aws:s3:::login-gov-transfer-utility",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}

data "aws_iam_policy_document" "transfer_utility_policy" {
  statement {
    sid    = "AllowObjectsDownload"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.transfer_bucket}/${var.env_name}/in/*"
    ]
  }
  statement {
    sid    = "AllowObjectsUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${local.transfer_bucket}/${var.env_name}/out/*"
    ]
  }
  statement {
    sid    = "AllowBucketListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      local.transfer_bucket,
    ]
  }
  statement {
    sid    = "AllowListing"
    effect = "Allow"
    actions = [
      "s3:ListObjectsV2",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["${var.env_name}/"]
    }
    resources = [
      "${local.transfer_bucket}/${var.env_name}/in/*",
    ]
  }
}

# this policy can allow any node/host to access the s3 artifacts bucket
data "aws_iam_policy_document" "download_artifacts_role_policy" {
  statement {
    sid    = "AllowBucketAndObjectsDownload"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/*",
    ]
  }

  # allow ls to work
  statement {
    sid    = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*",
    ]
  }
}

data "aws_iam_policy_document" "upload_artifacts_role_policy" {
  statement {
    sid    = "AllowBucketAndObjectsUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:CreateMultipartUpload"
    ]

    resources = [
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.app-artifacts.${data.aws_caller_identity.current.account_id}-*/common/*",
    ]
  }
}

data "aws_iam_policy_document" "usps_queue_policy" {
  count = var.enable_usps_status_updates ? 1 : 0
  statement {
    sid    = "ReadAttributes"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]

    resources = [
      var.usps_updates_sqs_arn
    ]
  }

  statement {
    sid    = "Messages"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]

    resources = [
      var.usps_updates_sqs_arn
    ]
  }
}

data "aws_iam_policy_document" "pivcac_cert_buckets_role_policy" {
  statement {
    sid = "AccessPIVCACBucket"
    actions = [
      "s3:List*",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov-pivcac-${var.env_name}.${data.aws_caller_identity.current.account_id}-*/*",
    ]
  }

  statement {
    sid = "AccessPIVCACPublicBucket"
    actions = [
      "s3:List*",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov-pivcac-public-cert-${var.env_name}.${data.aws_caller_identity.current.account_id}-*/*",
    ]
  }
}

# provide access to ssm-logs bucket and SSM KMS key in us-east-1, if enabled
data "aws_iam_policy_document" "ssm_kms_key_ue1" {
  statement {
    sid = "S3LoggingAccessForSSMInUSEast1"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::login-gov.${var.env_name}-ssm-logs.${data.aws_caller_identity.current.account_id}-us-east-1/*"
    ]
  }
  # KMS
  statement {
    sid = "KMSDecryptionAccessInUSEast1"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      var.ssm_kms_key_ue1
    ]
  }
}

data "aws_iam_policy_document" "puts_json_to_idp_dw_s3" {
  statement {
    sid = ""
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov-idp-dw-tasks-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}/*",
      "arn:aws:s3:::login-gov-idp-dw-tasks-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}",
    ]
  }
}

data "aws_iam_policy_document" "s3_idp_analytics_export_policy" {
  statement {
    sid = "AppAccessToS3IdpAnalyticsExport"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::login-gov-analytics-export-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}/table_summary_stats/*",
      "arn:aws:s3:::login-gov-analytics-export-${var.env_name}-${data.aws_caller_identity.current.account_id}-${var.region}/table_summary_stats",
    ]
  }
}






