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
}
