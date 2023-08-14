resource "aws_iam_instance_profile" "obproxy" {
  count       = var.external_instance_profile == "" ? 1 : 0
  name_prefix = var.use_prefix ? "${var.env_name}_obproxy_instance_profile" : null
  name        = var.use_prefix ? null : "${var.env_name}_obproxy_instance_profile"
  role        = var.external_role == "" ? aws_iam_role.obproxy[0].name : var.external_role
}
