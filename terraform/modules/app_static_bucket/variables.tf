variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "force_destroy_app_static_bucket" {
  type        = bool
  description = "Allow destruction of app static bucket even if not empty"
  default     = true
}

variable "root_domain" {
  type        = string
  description = "DNS domain to use as the root domain, e.g. login.gov"
}

variable "app_static_bucket_cross_account_access" {
  description = "Source roles from other accounts allowed access to the bucket"
  type        = list(string)
  default     = []
}

variable "cloudfront_custom_pages" {
  description = <<EOM
List of custom pages to populate into the static S3 bucket used by CloudFront for
custom error/maintenance handling. Format is {<s3-bucket-key> = <local-file-source>}"
EOM
  type        = map(string)
  default = {
    "5xx-codes/503.html"           = "./custom_pages/503.html",
    "maintenance/maintenance.html" = "./custom_pages/maintenance.html"
  }
}

variable "app_iam_role_arn" {
  type        = string
  description = "ARN of the role used by app hosts in the account"
}

variable "cloudfront_oai_iam_arn" {
  type        = string
  description = "ARN of the CloudFront Origin Access ID used for static access"
}