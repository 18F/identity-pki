variable "splunk_oncall_cloudwatch_endpoint" {
  description = <<EOM
Splunk On-Call AWS CloudWatch routing URI (minus /$routing-key)

The default value of UNSET will prevent creation of SNS subscriptions,
requiring you to update the /account/splunk_oncall/cloudwatch_endpoint SSM Parameter
then re-applying Terraform to create subscriptions.
EOM
  type        = string
  default     = "UNSET"
}

variable "splunk_oncall_newrelic_endpoint" {
  description = <<EOM
Splunk On-Call NewRelic routing URI (minus /$routing-key)

The default value of UNSET will prevent creation of SNS subscriptions,
requiring you to update the /account/splunk_oncall/newrelic_endpoint SSM Parameter
then re-applying Terraform to create subscriptions.
EOM
  type        = string
  default     = "UNSET"
}

variable "splunk_oncall_routing_keys" {
  description = "Splunk On-Call routing keys to deliver alerts to"
  type        = map(string)
  validation {
    condition = alltrue(
      [for r in keys(var.splunk_oncall_routing_keys) : can(regex("^[a-zA-Z0-9_-]+$", r))]
    )
    error_message = "Invalid routing key in var.splunk_oncall_routing_keys - Characters must be a letter, number, dash, or underscore"
  }
}

