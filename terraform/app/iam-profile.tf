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
# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "base-permissions" {
  name = "${var.env_name}-base-permissions"
  role = module.application_iam_roles.base_permissions_iam_role_name
}

# allow SSM service core functionality
resource "aws_iam_role_policy" "base-permissions-ssm-access" {
  name   = "${var.env_name}-base-permissions-ssm-access"
  role   = module.application_iam_roles.base_permissions_iam_role_id
  policy = module.ssm_uw2.ssm_access_role_policy
}