resource "aws_iam_instance_profile" "gitlab" {
  name = "${var.env_name}_gitlab_instance_profile"
  role = aws_iam_role.gitlab.name
}

resource "aws_iam_instance_profile" "gitlab_runner" {
  name = "${var.env_name}_gitlab_runner_instance_profile"
  role = aws_iam_role.gitlab_runner.name
}

resource "aws_iam_instance_profile" "obproxy" {
  name = "${var.env_name}_obproxy_instance_profile"
  role = aws_iam_role.obproxy.name
}
