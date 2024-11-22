# This policy can be used to allow the EC2 service to assume the role.
data "aws_iam_policy_document" "assume_role_from_vpc" {
  statement {
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

# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetAccess*",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucket*",
      "s3:GetDataAccess",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetMulti*",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion*",
      "s3:GetReplicationConfiguration",
      "s3:GetStorage*",
      "s3:List*"
    ]

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
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*",
    ]
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
      "s3:AbortMultipartUpload",
      "s3:AssociateAccessGrantsIdentityCenter",
      "s3:BypassGovernanceRetention",
      "s3:Create*",
      "s3:Delete*",
      "s3:Describe*",
      "s3:DissociateAccessGrantsIdentityCenter",
      "s3:GetAccelerateConfiguration",
      "s3:GetAccess*",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucket*",
      "s3:GetDataAccess",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetMulti*",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion*",
      "s3:GetReplicationConfiguration",
      "s3:GetStorage*",
      "s3:InitiateReplication",
      "s3:List*",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:PauseReplication",
      "s3:Put*",
      "s3:Replicate*",
      "s3:RestoreObject",
      "s3:SubmitMultiRegionAccessPointRoutes",
      "s3:TagResource",
      "s3:UntagResource",
      "s3:Update*"
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
      "s3:AbortMultipartUpload",
      "s3:AssociateAccessGrantsIdentityCenter",
      "s3:BypassGovernanceRetention",
      "s3:Create*",
      "s3:Delete*",
      "s3:Describe*",
      "s3:DissociateAccessGrantsIdentityCenter",
      "s3:GetAccelerateConfiguration",
      "s3:GetAccess*",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucket*",
      "s3:GetDataAccess",
      "s3:GetIntelligentTieringConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetJobTagging",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetMulti*",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion*",
      "s3:GetReplicationConfiguration",
      "s3:GetStorage*",
      "s3:InitiateReplication",
      "s3:List*",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:PauseReplication",
      "s3:Put*",
      "s3:Replicate*",
      "s3:RestoreObject",
      "s3:SubmitMultiRegionAccessPointRoutes",
      "s3:TagResource",
      "s3:UntagResource",
      "s3:Update*"
    ]
    resources = [
      "arn:aws:s3:::login-gov.app-secrets-*-${data.aws_caller_identity.current.account_id}/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-secrets-*-${data.aws_caller_identity.current.account_id}/${var.env_name}/*",
    ]
  }
}

data "aws_iam_policy_document" "application_secrets_secrets_manager_role_policy" {
  statement {
    sid    = "AllowApplicationSecretsSecretsManager${var.env_name}"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:redshift/${aws_redshift_cluster.redshift.cluster_identifier}-*",
    ]
  }
}

data "aws_iam_policy_document" "redshift_user_sync" {
  statement {
    sid    = "AllowRedshiftUserSyncExecute${var.env_name}"
    effect = "Allow"
    actions = [
      "redshift-data:ExecuteStatement",
    ]
    resources = [
      aws_redshift_cluster.redshift.arn
    ]
  }
  statement {
    sid    = "AllowRedshiftUserSyncDescribe${var.env_name}"
    effect = "Allow"
    actions = [
      "redshift-data:DescribeStatement",
      "redshift-data:GetStatementResult"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "redshift-data:statement-owner-iam-userid"
      values   = ["&{aws:userid}"]

    }
  }

}

#This policy is for writing log files to CloudWatch
data "aws_iam_policy_document" "cloudwatch-logs" {
  statement {
    sid = "allowCloudWatch"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
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
      "ec2:DescribeTags",
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
    resources = flatten([
      local.low_priority_alarm_actions,
      local.moderate_priority_alarm_actions
    ])
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

