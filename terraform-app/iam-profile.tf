# Role that represents the minimum permissions every instance should have for
# service discovery and citadel to work:
#
# - Secrets bucket access for citadel.
# - Self signed certs bucket access for service discovery.
# - Describe instances permission for service discovery.
#
# Add this as the role for an aws_iam_instance_profile.
#
# Note that terraform < 0.9 has a "roles" attribute on aws_iam_instance_profile
# even though there is a 1:1 mapping between iam_instance_profiles and
# iam_roles, so if your instance needs other permissions you can't use this.
resource "aws_iam_role" "base-permissions" {
    name = "${var.env_name}-base-permissions"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_from_vpc.json}"
}

# Role policy that associates it with the secrets_role_policy
resource "aws_iam_role_policy" "base-permissions-secrets" {
    name = "${var.env_name}-base-permissions-secrets"
    role = "${aws_iam_role.base-permissions.id}"
    policy = "${data.aws_iam_policy_document.secrets_role_policy.json}"
}

# Role policy that associates it with the certificates_role_policy
resource "aws_iam_role_policy" "base-permissions-certificates" {
    name = "${var.env_name}-base-permissions-certificates"
    role = "${aws_iam_role.base-permissions.id}"
    policy = "${data.aws_iam_policy_document.certificates_role_policy.json}"
}

# Role policy that associates it with the describe_instances_role_policy
resource "aws_iam_role_policy" "base-permissions-describe_instances" {
    name = "${var.env_name}-base-permissions-describe_instances"
    role = "${aws_iam_role.base-permissions.id}"
    policy = "${data.aws_iam_policy_document.describe_instances_role_policy.json}"
}

# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "base-permissions" {
    name = "${var.env_name}-base-permissions"
    # TODO: rename to "role" after upgrading to TF 0.9
    roles = ["${aws_iam_role.base-permissions.name}"]
}
