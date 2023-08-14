resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "dlm-ami-lifecycle-role-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  inline_policy {
    name = "dlm-lifecycle-role"

    #tfsec:ignore:aws-iam-no-policy-wildcards
    policy = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": "ec2:CreateTags",
                  "Resource": [
                      "arn:aws:ec2:*::snapshot/*",
                      "arn:aws:ec2:*::image/*"
                  ]
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:DescribeImages",
                      "ec2:DescribeInstances",
                      "ec2:DescribeImageAttribute",
                      "ec2:DescribeVolumes",
                      "ec2:DescribeSnapshots"
                  ],
                  "Resource": "*"
              },
              {
                  "Effect": "Allow",
                  "Action": "ec2:DeleteSnapshot",
                  "Resource": "arn:aws:ec2:*::snapshot/*"
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:ResetImageAttribute",
                      "ec2:DeregisterImage",
                      "ec2:CreateImage",
                      "ec2:CopyImage",
                      "ec2:ModifyImageAttribute"
                  ],
                  "Resource": "*"
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:EnableImageDeprecation",
                      "ec2:DisableImageDeprecation"
                  ],
                  "Resource": "arn:aws:ec2:*::image/*"
              }
          ]
      }
    EOM
  }
}

resource "aws_dlm_lifecycle_policy" "main" {
  description        = "Expire Old AMIs After 30 Days"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  tags = {
    Name = "Expire AMIs"
  }

  policy_details {
    policy_type    = "IMAGE_MANAGEMENT"
    resource_types = ["INSTANCE"]

    schedule {
      name = "AMI Deprecate after ${var.ami_deprecated_days} Days and Delete After ${var.ami_deleted_days} Days"

      create_rule {
        cron_expression = "cron(0 8 ? * * *)"
      }

      # The amount of time to retain each snapshot
      # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/deregister-ami.html

      retain_rule {
        interval      = var.ami_deleted_days
        interval_unit = "DAYS"
      }

      # Specifies the period after which to mark an AMI as not for use, 
      # remove from DescribeImages API calls, while not affecting ec2 instances 
      # and ASG that refrence the AMIs
      # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ami-deprecate.html

      deprecate_rule {
        interval      = var.ami_deprecated_days
        interval_unit = "DAYS"
      }
    }

    parameters {
      no_reboot = true
    }

    target_tags = {
      github_repo = "identity-base-image"
    }
  }
}
