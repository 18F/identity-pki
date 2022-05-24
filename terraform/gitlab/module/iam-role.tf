resource "aws_iam_role" "gitlab" {
  name_prefix        = "${var.env_name}_gitlab_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json

  inline_policy {
    name   = "${var.env_name}-gitlab-auto-eip"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEIPDescribeAndAssociate",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress"
            ],
            "Resource": "*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-certificates"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCertificatesBucketIntegrationTest",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
              "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/",
              "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*"
            ]
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-cloudwatch-agent"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "allowCloudWatchAgent",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-cloudwatch-logs"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "allowCloudWatch",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-describe_instances"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowDescribeInstancesIntegrationTest",
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-ebvolume"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/domain": "${var.env_name}.${var.root_domain}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Name": "login-gitaly-${var.env_name}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Name": "login-gitlab-${var.env_name}"
                }
            }
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-s3buckets"
    policy = <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket"
          ],
          "Resource": [
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabartifacts-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabbackups-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabexternaldiffs-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlablfsobjects-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabuploads-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabpackages-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabdependcyproxy-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabtfstate-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabpages-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabartifacts-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabbackups-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabexternaldiffs-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlablfsobjects-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabuploads-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabpackages-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabdependcyproxy-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabtfstate-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabpages-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}/*",
              "arn:aws:s3:::login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}/*"
          ]
      }
  ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-secrets"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowBucketAndObjects",
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": [
                "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
                "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
                "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
                "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/"
            ]
        },
        {
            "Sid": "AllowRootAndTopListing",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
            "Condition": {
                "StringEquals": {
                    "s3:delimiter": [
                        "/"
                    ],
                    "s3:prefix": [
                        "",
                        "common/",
                        "${var.env_name}/"
                    ]
                }
            }
        },
        {
            "Sid": "AllowSubListing",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "common/",
                        "${var.env_name}/*"
                    ]
                }
            }
        },
        {
            "Sid": "AllowCompleteLifecycleHook",
            "Effect": "Allow",
            "Action": [
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CompleteLifecycleAction"
            ],
            "Resource": "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
        }
    ]
}
EOM
  }

  # allow all instances to send a dying SNS notice
  inline_policy {
    name   = "${var.env_name}-gitlab-sns-publish-alerts"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "allowSNSPublish",
            "Effect": "Allow",
            "Action": "SNS:Publish",
            "Resource": "${var.slack_events_sns_hook_arn}"
        }
    ]
}
EOM
  }

  # allow SSM access via documents / key generation + usage
  inline_policy {
    name   = "${var.env_name}-gitlab-ssm-access"
    policy = module.ssm.ssm_access_role_policy
  }
}
