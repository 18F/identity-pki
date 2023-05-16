
# TODO
# Role that instances can use to access stuff in citadel. Add this as the role
# for an aws_iam_instance_profile. Note that terraform < 0.9 has a "roles"
# attribute on aws_iam_instance_profile even though there is a 1:1 mapping
# between iam_instance_profiles and iam_roles.
# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "citadel-client" {
  name = "${var.env_name}-citadel-client"
  role = module.application_iam_roles.citadel_client_iam_role_name
}
