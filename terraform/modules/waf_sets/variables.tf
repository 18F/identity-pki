variable "fisma_tag" {
  default = "Q-LG"
}

variable "app_name" {
  type        = string
  description = <<EOM
Name of the application (currently 'idp' or 'gitlab') using Load Balancers
that WAFv2 ACL(s) will be associated with. Used for naming regex / IP sets.
EOM
  default     = "idp"
}

variable "privileged_cidr_blocks_v4" {
  type        = list(string)
  description = <<EOM
List of additional IPv4 CIDR blocks that should be allowed access
through the WAFv2 web ACL(s) to restricted endpoints.
EOM
  default     = []
}

variable "privileged_cidr_blocks_v6" {
  type        = list(string)
  description = <<EOM
List of additional IPv6 CIDR blocks that should be allowed access
through the WAFv2 web ACL(s) to restricted endpoints.
EOM
  default     = []
}

variable "header_block_regex" {
  type = list(object({
    field_name = string
    patterns   = list(string)
    }
    )
  )
  description = "Map of regexes matching headers to block"
  default     = []
}

variable "ip_block_cidrs_v4" {
  type        = list(string)
  description = "IPv4 addresses with CIDR mask to block"
  default = [ # REMEMBER THE CIDR MASK! For a single IPv4 IP just add /32 at the end.
    #"44.230.151.136/32", # DO NOT ADD!  This is our Nessus scanner and it will scan, as scanners do!
    "35.164.226.34/32",   # 2022-11-25 - Noisy scanner blocked per GSA IR
    "45.156.25.223/32",   # 2022-04-29 - Log4j scanner blocked per-GSA IR
    "141.170.198.141/32", # 2022-05-10 - Noisy scanner from BA generating some 502s
    "103.114.162.12/32",  # 2022-06-03 - Singapore 502ing with app requests
    "185.170.235.237/32"  # 2023-04-12 - Cyprus DDoS / feroxbuster-2.9.1
  ]

  validation {
    condition     = length(var.ip_block_cidrs_v4) < 100
    error_message = "IP sets can only have a maximum of 100, per account, per region"
  }
}

variable "ip_block_cidrs_v6" {
  type        = list(string)
  description = "IPv6 addresses with CIDR mask to block"
  default = [       # REMEMBER THE CIDR MASK! For a single IPv6 IP just add /128 at the end.
    "2001:DB8::/32" # https://www.rfc-editor.org/rfc/rfc3849.txt
  ]

  validation {
    condition     = length(var.ip_block_cidrs_v6) < 100
    error_message = "IP sets can only have a maximum of 100, per account, per region"
  }
}

variable "limit_exempt_paths" {
  type        = list(string)
  description = "Set of regexes to exempt from rate-limiting acl rules"
  default = [
    "^/api/.*",
    "^/\\.well-known/.*"
  ]
}

variable "query_block_regex" {
  type        = list(string)
  description = "Set of regexes to filter query strings for blocking"
  default     = []
}

variable "relaxed_uri_paths" {
  type        = map(string)
  description = "Map of regexes matching paths to use less strict WAFv2 protections on"
  # Use these sparingly for paths accepting files/other content that triggers
  # false positives but has a low risk of being exploited.  Document additions!
  default = {
    "docauth_image_upload"    = "^/api/verify/images"         # https://github.com/18F/identity-devops/issues/4092
    "login_form"              = "^/([a-z]{2}/)?$"             # https://github.com/18F/identity-devops/issues/4563
    "password_screening_flow" = "^/([a-z]{2}/)?verify/review" # https://github.com/18F/identity-devops/issues/4563
    "OIDC_authorization"      = "^/openid_connect/authorize"  # https://github.com/18F/identity-devops/issues/4563
    "account_deletion"        = "^/account/delete"            # https://github.com/18F/identity-devops/issues/6127
  }
}

variable "restricted_paths" {
  type        = map(list(string))
  description = <<EOM
Map with two keys for WAFv2 configuration: A list of regex matches of paths
to restrict to privileged IPs, and a list of paths to exclude.
EOM
  default = {
    paths = [
      "^/api/irs_attempts_api/.*",
    ]
    exclusions = [
    ]
  }
}

variable "wafv2_web_acl_scope" {
  type        = string
  description = "Scope where WAFv2 rules are created. Must be REGIONAL or CLOUDFRONT"
  default     = "REGIONAL"

  validation {
    condition     = var.wafv2_web_acl_scope == "REGIONAL" || var.wafv2_web_acl_scope == "CLOUDFRONT"
    error_message = "wafv2_web_acl_scope must be either set to either REGIONAL or CLOUDFRONT"
  }
}
