# For now not much is here. Subscriptions of type "email" are not supported
# in Terraform, because creating one does not create an ARN immediately.

resource "aws_sns_topic" "devops_high_priority" {
  name = "devops_high_priority"
}

# Subscription that connects the SNS topic to paging.
resource "aws_sns_topic_subscription" "opsgenie_devops_high" {
  topic_arn = "${aws_sns_topic.devops_high_priority.arn}"
  protocol  = "https"
  # TODO: make this a variable
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatch?apiKey=a0afabc6-eca0-477d-b05a-0e6dc6990729"
}
