variable "resource_arn" {
  description = "AWS ARN of the resource that will be updated"
  type        = string
}

variable "action" {
  description = "Value for the Automated Application Layer DDOS Mitigation setting for AWS Shield. Valid values are Disable, Block, or Count"
  type        = string
  default     = "Disable"
  validation {
    condition     = contains(["Disable", "Block", "Count"], var.action)
    error_message = "shield_ddos action is not valid. Valid options are \"Disable\", \"Block\", or \"Count\""
  }
}

variable "action_command" {
  description = "List of string values that can be appended to the executed AWS command based on the action being taken"
  default = {
    "Disable" = "",
    "Count"   = " --action \"Count={}\""
    "Block"   = " --action \"Block={}\""
  }
}
