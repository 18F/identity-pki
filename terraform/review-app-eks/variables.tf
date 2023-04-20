variable "region" {
  description = "region where it all happens"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "name of cluster"
  type        = string
  default     = "review_app"
}

variable "dnszone" {
  description = "dns zone that external_dns will be able to edit"
  type        = string
  default     = "review-app.identitysandbox.gov"
}
