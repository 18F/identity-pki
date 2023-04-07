variable "splunk_oncall_routing_keys" {
  description = "Splunk OnCall routing keys to deliver alerts to"
  type        = map(string)
  validation {
    condition = alltrue(
      [for r in keys(var.splunk_oncall_routing_keys) : can(regex("^[a-zA-Z0-9_-]+$", r))]
    )
    error_message = "Invalid routing key in var.splunk_oncall_routing_keys - Characters must be a letter, number, dash, or underscore"
  }
}

