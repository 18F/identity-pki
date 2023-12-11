variable "key_list" {
  description = "List of keys with Kubernetes metadata, data sections for different sources and purposes, and secret key name."
  type = map(object({
    source = string
    metadata = object({
      name                = string
      namespace           = string
      s3_bucket           = optional(string)
      s3_key              = optional(string)
      secrets_manager_id  = optional(string)
      secrets_manager_key = optional(string)
      labels              = optional(map(string))
      annotations         = optional(map(string))
    })
    data          = map(string)
    secretKeyName = string # This field specifies the key name for the secret
  }))
  default = {
    "identity-eks-charts" = {
      source = "secrets-manager" # Either secrets-manager or s3
      metadata = {               # Any kubernetes secret metadata you want to specify
        name                = "identity-eks-charts"
        secrets_manager_id  = "identity-eks-charts"
        secrets_manager_key = "sshPrivateKey"
        namespace           = "argocd"
        labels = {
          "argocd.argoproj.io/secret-type" = "repository"
        }
        annotations = {
          "example.annotation.com" = "true"
        }
      }
      data = { # Any other non secret data you want included in the secret
        "type" = "git"
        "url"  = "git@gitlab.login.gov:identity-eks-charts.git"
      }
      secretKeyName = "sshPrivateKey" # The key inside our kubernetes secret that the value is stored under
    }
  }
}