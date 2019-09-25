# For now not much is here. Subscriptions of type "email" are not supported
# in Terraform, because creating one does not create an ARN immediately.

resource "aws_sns_topic" "devops_high_priority_pinpoint" {
  name = "devops_high_priority_pinpoint"
}

# Subscription that connects the SNS topic to paging.
resource "aws_sns_topic_subscription" "opsgenie_devops_high" {
  topic_arn = "${aws_sns_topic.devops_high_priority_pinpoint.arn}"
  protocol  = "https"
  endpoint  = "${var.opsgenie_devops_high_endpoint}"
  endpoint_auto_confirms = true
}
