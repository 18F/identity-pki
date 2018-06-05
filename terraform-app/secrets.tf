# Roles and policies relevant to citadel S3 secrets
#
# Understanding IAM roles, policies, and instance profiles.
#
# An EC2 instance can have an IAM instance profile that gives it privileges
# (aws_iam_instance_profile). This profile must have exactly one IAM Role
# (aws_iam_role). An IAM role may have inline policies that determine what
# privileges it grants, or it may have several policies associated with it.
# Each policy (aws_iam_role_policy) is a 1:many attachment on roles that grants
# certain actions on certain resources as specified directly in a JSON document
# or in a data object aws_iam_policy_document.
#
#
# Usage: there are two ways for callers to use these resources:
#
# 1. Reuse the IAM instance profile.
#
#   Choose this option when you don't need any permissions other than the
#   common policy here.
#
#   Example:
#     resource "aws_launch_configuration" "foo" {
#       ...
#       iam_instance_profile = "${aws_iam_instance_profile.citadel-client.name}"
#     }
#
# 2. Define a custom role and attach the existing policy document.
#
#   Choose this option when your IAM role also needs custom permissions.
#
#   Example:
#     resource "aws_iam_instance_profile" "custom" {
#       name = "${var.env_name}_customprofile
#       role = "${aws_iam_role.custom.name}"
#     }
#
#     resource "aws_iam_role" "custom" {
#       name = "${var.env_name}-customrole"
#       assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
#     }
#
#     resource "aws_iam_role_policy "somecustomstuff" {
#       name = "${var.env_name}-customrole-customstuff"
#       role = "${aws_iam_role.custom.id}"
#       policy = <<EOF
#     ... JSON ...
#     EOF
#     }
#
#     resource "aws_iam_role_policy" "custom-citadel" {
#       name = "${var.env_name}-customrole-citadel"
#       role = "${aws_iam_role.custom.id}"
#       policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
#     }
#

# this policy can allow any node/host to access the s3 secrets bucket
data "aws_iam_policy_document" "secrets_role_policy" {
  statement {
    sid = "AllowBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    # TODO: login-gov-secrets-test and login-gov-secrets are deprecated
    resources = [
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
      "arn:aws:s3:::login-gov-secrets-test/common/",
      "arn:aws:s3:::login-gov-secrets-test/common/*",
      "arn:aws:s3:::login-gov-secrets/common/",
      "arn:aws:s3:::login-gov-secrets/common/*",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
      "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/",
      "arn:aws:s3:::login-gov-secrets-test/${var.env_name}/*",
      "arn:aws:s3:::login-gov-secrets/${var.env_name}/",
      "arn:aws:s3:::login-gov-secrets/${var.env_name}/*"
    ]
  }

  # allow ls to work
  statement {
    sid = "AllowRootAndTopListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    condition {
      test = "StringEquals"
      variable = "s3:prefix"
      values = ["", "common/", "${var.env_name}/"]
    }
    condition {
      test = "StringEquals"
      variable = "s3:delimiter"
      values = ["/"]
    }
    resources = [
      "arn:aws:s3:::login-gov-secrets-test",
      "arn:aws:s3:::login-gov-secrets",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # allow subdirectory ls
  statement {
    sid = "AllowSubListing"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = ["common/", "${var.env_name}/*"]
    }
    resources = [
      "arn:aws:s3:::login-gov-secrets-test",
      "arn:aws:s3:::login-gov-secrets",
      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
      "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-*",
    ]
  }

  # Allow notifying ASG lifecycle hooks. This isn't a great place for this
  # permission since not actually related, but it's useful to put here because
  # all of our ASG instances need it.
  statement {
    sid = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat"
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
    ]
  }
}

# Role that instances can use to access stuff in citadel. Add this as the role
# for an aws_iam_instance_profile. Note that terraform < 0.9 has a "roles"
# attribute on aws_iam_instance_profile even though there is a 1:1 mapping
# between iam_instance_profiles and iam_roles.
resource "aws_iam_role" "citadel-client" {
    name = "${var.env_name}-citadel-client"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "citadel-client" {
    name = "${var.env_name}-citadel-client"
    role = "${aws_iam_role.citadel-client.id}"
    policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "citadel-client" {
    name = "${var.env_name}-citadel-client"
    role = "${aws_iam_role.citadel-client.name}"
}
