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

variable "pivcac_dnszone" {
  description = "dns zone that external_dns will be able to edit for pivcac"
  type        = string
  default     = "pivcac.identitysandbox.gov"
}

variable "ecr_repo_names" {
  description = "list of ecr repos to create"
  type        = list(string)
  default     = ["idp", "worker", "pivcac", "app"]
}