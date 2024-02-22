variable "region" {
  description = "region where it all happens"
  type        = string
  default     = "us-west-2"
}

variable "kubernetes_version" {
  description = "The desired Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.27"

}

variable "cluster_name" {
  description = "name of cluster"
  type        = string
  default     = "review"
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
  default     = ["idp", "worker", "pivcac", "app", "dashboard"]
}