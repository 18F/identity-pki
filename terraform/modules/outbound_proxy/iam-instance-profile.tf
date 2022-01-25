resource "aws_iam_instance_profile" "obproxy" {
  name_prefix = "${var.env_name}_obproxy_instance_profile"
  role        = aws_iam_role.obproxy.name
}
