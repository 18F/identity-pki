variable "dashboard_name" {
  type        = string
  description = "Name of the Cloudwatch dashboard to create"
}

variable "dashboard_definition" {
  type = object({
    variables = optional(list(any))
    widgets   = list(any)
  })
  description = "The Dashboard definition, exported from Cloudwatch and parsed into a Terraform object"
}

variable "filter_sps" {
  type = list(object({
    name    = string
    issuers = list(string)
  }))
  description = "List of SPs available for filtering."
  default     = []
  validation {
    condition = alltrue([
      for sp in var.filter_sps : length("properties.service_provider in ${jsonencode(sp.issuers)}") <= 255
    ])
    error_message = "At least one item in filter_sps is invalid. For each entry in filter_sps, the combined length of issuers must be <= 224 characters when JSON encoded due to Cloudwatch limits."
  }
}
