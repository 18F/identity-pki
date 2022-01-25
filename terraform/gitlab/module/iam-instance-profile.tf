resource "aws_iam_instance_profile" "gitlab" {
  name_prefix = "${var.env_name}_gitlab_instance_profile"
  role        = aws_iam_role.gitlab.name
}

resource "aws_iam_instance_profile" "gitlab_runner" {
  name_prefix = "${var.env_name}_gitlab_runner_instance_profile"
  role        = aws_iam_role.gitlab_runner.name
}
