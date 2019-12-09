# There aren't many resources we can manage in Terraform

resource "aws_pinpoint_app" "main" {
  name = "${var.pinpoint_app_name}"
}

resource "aws_pinpoint_sms_channel" "sms" {
  application_id = "${aws_pinpoint_app.main.application_id}"
  enabled        = true

  # sender_id - (Optional) Sender identifier of your messages.
  # short_code - (Optional) The Short Code registered with the phone provider.
}

output "pinpoint_app_id" {
  value = "${aws_pinpoint_app.main.application_id}"
}
