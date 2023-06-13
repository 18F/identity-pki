resource "aws_iam_instance_profile" "gitlab_runner" {
  name_prefix = "${var.env_name}_${var.gitlab_runner_pool_name}_gitlab_runner_instance_profile"
  role        = aws_iam_role.gitlab_runner.name
}