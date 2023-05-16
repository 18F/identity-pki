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
# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "service-discovery" {
  name = "${var.env_name}-service-discovery"
  role = module.application_iam_roles.service_discovery_iam_role_name
}

