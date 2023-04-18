output "sns_topic_arns" {
  description = "ARNs of the SNS topics"
  value = {
    for k in keys(var.splunk_oncall_routing_keys) : k => aws_sns_topic.splunk_oncall_alert[k].arn
  }
}

