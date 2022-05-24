resource "aws_iam_role" "obproxy" {
  name_prefix        = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = <<-EOM
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": "allowVPC"
        }
      ]
    }
  EOM

  inline_policy {
    name   = "${var.env_name}-obproxy-auto-eip"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-certificates"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-cloudwatch-agent"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-cloudwatch-logs"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-describe_instances"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-secrets"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-sns-publish-alerts"
    policy = <<-EOM
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
    name   = "${var.env_name}-obproxy-ssm-access"
    policy = var.ssm_access_policy
  }
}
