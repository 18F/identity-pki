resource "aws_iam_instance_profile" "base-permissions" {
  name = "${var.env_name}-base-permissions"
  role = aws_iam_role.base-permissions.name
}

# IAM instance profile using the citadel client role
resource "aws_iam_instance_profile" "citadel-client" {
  name = "${var.env_name}-citadel-client"
  role = aws_iam_role.citadel-client.name
}

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
