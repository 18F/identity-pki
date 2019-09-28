# There aren't many resources we can manage in Terraform

resource "aws_pinpoint_app" "main" {
  name = "${var.pinpoint_app_name}"
}
