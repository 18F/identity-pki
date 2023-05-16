# Very similar to terraform/app/idp.tf

resource "aws_iam_instance_profile" "migration" {
  name = "${var.env_name}_migration_instance_profile"
  role = module.application_iam_roles.migration_iam_role_name
}