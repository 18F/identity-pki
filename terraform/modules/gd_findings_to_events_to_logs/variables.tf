variable "sqs_queue_url" {
  description = "SQS Queue URL"
  # default     = "https://sqs.us-west-2.amazonaws.com/752281881774/elp-guardduty-lg.fifo"
  type = string
}
variable "sqs_queue_arn" {
  description = "SQS Queue arn"
  type        = string
  # default = "arn:aws:sqs:us-west-2:752281881774:elp-guardduty-lg.fifo"
}

variable "cloudwatch_event_rule_pattern_detail_type" {
   description = <<-DOC
  The detail-type pattern used to match events that will be sent to SQS.
  For more information, see:
  https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/CloudWatchEventsandEventPatterns.html
  https://docs.aws.amazon.com/eventbridge/latest/userguide/event-types.html
  https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_cloudwatch.html
  DOC
  type        = string
  default     = "GuardDuty Finding"

}
