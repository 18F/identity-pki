resource "aws_iam_role" "gitlab" {
  name_prefix        = "${var.env_name}_gitlab_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json
}

data "aws_iam_policy_document" "gitlab_auto_eip" {
  statement {
    sid    = "AllowEIPDescribeAndAssociate"
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "gitlab_certificates" {
  statement {
    sid     = "AllowCertificatesBucketIntegrationTest"
    effect  = "Allow"
    actions = ["s3:*", ]
    resources = [
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/",
      "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "gitlab_cloudwatch_agent" {
  statement {
    sid    = "allowCloudWatchAgent"
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "gitlab_rds_modify" {
  statement {
    sid    = "allowRDSpasswordReset"
    effect = "Allow"
    actions = [
      "rds:ModifyDBInstance"
    ]
    resources = [
      aws_db_instance.gitlab.arn
    ]
  }
}

data "aws_iam_policy_document" "gitlab_cloudwatch_logs" {
  statement {
    sid    = "allowCloudWatch"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "gitlab_describe_instances" {
  statement {
    sid    = "AllowDescribeInstancesIntegrationTest"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "gitlab_ebvolume" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/domain"
      values = [
        "${var.env_name}.${var.root_domain}"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Name"
      values = [
        "login-gitaly-${var.env_name}"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Name"
      values = [
        "login-gitlab-${var.env_name}"
      ]
    }
  }
}

data "aws_iam_policy_document" "gitlab_s3buckets" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = flatten([
      [
        for bucket in aws_s3_bucket.gitlab_buckets : bucket.arn
      ],
      [
        aws_s3_bucket.backups.arn,
        aws_s3_bucket.backups_dr.arn,
        aws_s3_bucket.config.arn,
        aws_s3_bucket.cache.arn,
      ]
    ])
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.backups_dr.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = formatlist("%s/*",
      flatten([
        [
          for bucket in aws_s3_bucket.gitlab_buckets : bucket.arn
        ],
        [
          aws_s3_bucket.backups.arn,
          aws_s3_bucket.config.arn,
          aws_s3_bucket.cache.arn,
        ]
      ])
    )
  }
}

data "aws_iam_policy_document" "gitlab_secrets" {
  statement {
    sid    = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/"
    ]
  }
  statement {
    sid     = "AllowRootAndTopListing"
    effect  = "Allow"
    actions = ["s3:ListBucket", ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values = [
        "/"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        "",
        "common/",
        "${var.env_name}/"
      ]
    }
  }
  statement {
    sid    = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "common/",
        "${var.env_name}/*"
      ]
    }
  }
  statement {
    sid    = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
    ]
  }
}

# allow all instances to send a dying SNS notice
data "aws_iam_policy_document" "gitlab_sns_publish_alerts" {
  statement {
    sid     = "allowSNSPublish"
    effect  = "Allow"
    actions = ["SNS:Publish", ]
    resources = [
      var.slack_events_sns_hook_arn
    ]
  }
}

resource "aws_iam_role_policy" "gitlab_auto_eip" {
  name   = "${var.env_name}-gitlab-auto-eip"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_auto_eip.json
}

resource "aws_iam_role_policy" "gitlab_certificates" {
  name   = "${var.env_name}-gitlab-certificates"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_certificates.json
}

resource "aws_iam_role_policy" "gitlab_cloudwatch_agent" {
  name   = "${var.env_name}-gitlab-cloudwatch-agent"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_cloudwatch_agent.json
}

resource "aws_iam_role_policy" "gitlab_rds_modify" {
  name   = "${var.env_name}-gitlab-rds-modify"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_rds_modify.json
}

resource "aws_iam_role_policy" "gitlab_cloudwatch_logs" {
  name   = "${var.env_name}-gitlab-cloudwatch-logs"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_cloudwatch_logs.json
}

resource "aws_iam_role_policy" "gitlab_describe_instances" {
  name   = "${var.env_name}-gitlab-describe_instances"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_describe_instances.json
}

resource "aws_iam_role_policy" "gitlab_ebvolume" {
  name   = "${var.env_name}-gitlab-ebvolume"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_ebvolume.json
}

resource "aws_iam_role_policy" "gitlab_s3buckets" {
  name   = "${var.env_name}-gitlab-s3buckets"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_s3buckets.json
}

resource "aws_iam_role_policy" "gitlab_secrets" {
  name   = "${var.env_name}-gitlab-secrets"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_secrets.json
}

resource "aws_iam_role_policy" "gitlab_sns_publish_alerts" {
  name   = "${var.env_name}-gitlab-sns-publish-alerts"
  role   = aws_iam_role.gitlab.name
  policy = data.aws_iam_policy_document.gitlab_sns_publish_alerts.json
}

# allow SSM access via documents / key generation + usage
resource "aws_iam_role_policy" "gitlab_ssm_access" {
  name   = "${var.env_name}-gitlab-ssm-access"
  role   = aws_iam_role.gitlab.name
  policy = module.ssm.ssm_access_role_policy
}

data "aws_iam_policy_document" "gitlab_s3_repl_assume" {
  statement {
    sid = "GitlabS3AssumeRole"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "s3_replication" {
  name_prefix        = "${var.env_name}_gitlab_s3_repl"
  assume_role_policy = data.aws_iam_policy_document.gitlab_s3_repl_assume.json
}

data "aws_iam_policy_document" "gitlab_s3_repl" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.backups.arn
    ]
  }
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.backups.arn}/*"
    ]
  }
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.backups_dr.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "gitlab_s3_repl" {
  name   = "${var.env_name}-gitlab-s3_repl"
  role   = aws_iam_role.s3_replication.name
  policy = data.aws_iam_policy_document.gitlab_s3_repl.json
}
