variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "scan_on_push_filter" {
  description = "Filter for repos to set scan on push"
  type        = string
  default     = "*"
}

variable "continuous_scan_filter" {
  description = "Filter for repos to set continuous scan"
  type        = string
  default     = "*"
}
