output "usw2_sns_topic_arns" {
  description = "ARNs of the SNS topics in US-WEST-2."
  value = [
    for k in keys(var.splunk_oncall_routing_keys) : aws_sns_topic.splunk_oncall_alert_usw2[k].arn
  ]
}

output "use1_sns_topic_arns" {
  description = "ARNs of the SNS topics in US-EAST-1."
  value = [
    for k in keys(var.splunk_oncall_routing_keys) : aws_sns_topic.splunk_oncall_alert_use1[k].arn
  ]
}
