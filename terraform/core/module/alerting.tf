// For now not much is here. Subscriptions of type "email" are not supported
// in Terraform, because creating one does not create an ARN immediately. If we
//  move to something that takes requests in HTTPS form (like OpsGenie) we
// should add those subscriptions here.

resource "aws_sns_topic" "devops_high_priority" {
  name = "devops_high_priority"
}

// Everbridge's email subscription to this topic is
// arn:aws:sns:us-west-2:555546682965:devops_high_priority:9018fa90-bcb2-4236-87af-216bbd62b768

// May do nothing after 20181219, but better to have it documented here in case
// we buy it again.
resource "aws_sns_topic_subscription" "opsgenie_devops_high" {
  topic_arn = aws_sns_topic.devops_high_priority.arn
  protocol  = "https"
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatch?apiKey=a0afabc6-eca0-477d-b05a-0e6dc6990729"
}

