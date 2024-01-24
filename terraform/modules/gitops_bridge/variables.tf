variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = ""
}

variable "gitops_applications" {
  description = "List of applications to be managed by Argo CD"
  type = list(object({
    name : string
    repoURL : string
    path : string
    targetRevision : string
    valueFiles : list(string)
    helmValues : string
  }))
}

variable "metadata" {
  description = "Metadata for GitOps Bridge to load into the cluster"
  default     = {}
}