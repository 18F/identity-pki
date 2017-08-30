# Roles and policies relevant to service discovery.
#
# See secrets.tf in this directory for documentation on IAM roles, policies, and
# instance profiles.

# This policy can allow any node/host to describe instances (for service
# discovery)
data "aws_iam_policy_document" "describe_instances_role_policy" {
  statement {
    sid = "AllowDescribeInstancesIntegrationTest"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = [
       "*"
    ]
  }
}

# This policy can allow any node/host to access the bucket containing our self
# signed certificates (for service registration and discovery)
data "aws_iam_policy_document" "certificates_role_policy" {
  statement {
    sid = "AllowCertificatesBucketIntegrationTest"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    # The first two entries here are legacy and only here for backwards
    # compatibility.  They can be removed when the chef changes in
    # https://github.com/18F/identity-devops/pull/574 are rolled out to all
    # environments.
    resources = [
       "arn:aws:s3:::${var.certificates_bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}/${var.env_name}/",
       "arn:aws:s3:::${var.certificates_bucket_name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}/${var.env_name}/*",
       "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/",
       "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*",
    ]
  }
}

# Role that represents the minimum permissions every instance should have for
# service discovery to work:
#
# - Self signed certs bucket access.
# - Describe instances permission.
#
# Add this as the role for an aws_iam_instance_profile.
#
# Note that terraform < 0.9 has a "roles" attribute on aws_iam_instance_profile
# even though there is a 1:1 mapping between iam_instance_profiles and
# iam_roles, so if your instance needs other permissions you can't use this.
resource "aws_iam_role" "service-discovery" {
    name = "${var.env_name}-service-discovery"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "service-discovery-certificates" {
    name = "${var.env_name}-service-discovery-certificates"
    role = "${aws_iam_role.service-discovery.id}"
    policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "service-discovery-describe_instances" {
    name = "${var.env_name}-service-discovery-describe_instances"
    role = "${aws_iam_role.service-discovery.id}"
    policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "service-discovery" {
    name = "${var.env_name}-service-discovery"
    # TODO: rename to "role" after upgrading to TF 0.9
    roles = ["${aws_iam_role.service-discovery.name}"]
}
