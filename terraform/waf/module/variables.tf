variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "app" {
  description = <<EOM
Name of the application (currently 'idp' or 'gitlab') using Load Balancers
that WAFv2 ACL(s) will be associated with. Used for naming web ACL configs.
EOM
  type        = string
  default     = "idp"
}

variable "enforce" {
  description = "Block (true) or count (false) traffic matching WAF ACL rules."
  type        = bool
  default     = false
}

variable "enforce_rate_limit" {
  description = "Enforce rate-limiting of all traffic based on source IP."
  type        = bool
  default     = false
}

# WIP not ready for prod deployment
variable "enforce_waf_captcha" {
  description = "Enforce captcha before login page."
  type        = bool
  default     = false
}

# WIP not ready for prod deployment
variable "enforce_waf_challenge" {
  description = "Enforce challenge before login page."
  type        = bool
  default     = false
}

# description of rules in bot control rule set:
# https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-bot.html
variable "bot_control_exclusions" {
  description = <<EOM
List of rules to /exclude/ for AWSManagedRulesBotControlRuleSet.
Populate to define rules to COUNT (and BLOCK all others),
or leave blank to skip applying the bot control ruleset
EOM
  type        = list(string)
  default = [
    "CategoryAdvertising",
    "CategoryArchiver",
    "CategoryContentFetcher",
    "CategoryEmailClient",
    "CategoryHttpLibrary",
    "CategoryLinkChecker",
    "CategoryMiscellaneous",
    "CategoryMonitoring",
    "CategoryScrapingFramework",
    "CategorySearchEngine",
    "CategorySecurity",
    "CategorySeo",
    "CategorySocialMedia",
    "SignalAutomatedBrowser",
    "SignalKnownBotDataCenter",
    "SignalNonBrowserUserAgent"
  ]
}

# description of rules in each AWS managed ruleset 
# https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
variable "ip_reputation_ruleset_exclusions" {
  description = "List of rules to exclude for AWSManagedRulesAmazonIpReputationList"
  type        = list(string)
  default     = []
}

variable "common_ruleset_exclusions" {
  description = "List of rules to exclude for AWSManagedRulesCommonRuleSet"
  type        = list(string)
  default = [
    # AWS description: "Inspects the values of the request body and blocks requests
    # attempting to exploit RFI (Remote File Inclusion) in web applications.
    # Examples include patterns like ://." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3085
    "GenericRFI_BODY",
    # AWS description: "Inspects the values of all query parameters & blocks requests
    # attempting to  exploit RFI (Remote File Inclusion) in web applications.
    # Examples include patterns like ://." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3100
    "GenericRFI_QUERYARGUMENTS",
    # AWS description: "Verifies that the URI query string length is within the
    # standard boundary for applications." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3100
    "SizeRestrictions_QUERYSTRING",
    # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata
    # from the request query arguments." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3100
    "EC2MetaDataSSRF_QUERYARGUMENTS",
    # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata
    # from the request cookie." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3100
    "EC2MetaDataSSRF_BODY",
    # AWS description: "Blocks requests with no HTTP User-Agent header."
    # For request details see issue:
    # https://github.com/18F/identity-devops/issues/3100
    "NoUserAgent_HEADER",
    # AWS description: "Inspects the value of query arguments and blocks common
    # cross-site scripting (XSS) patterns using the built-in XSS detection 
    # rule in AWS WAF. Example patterns include scripts like
    # <script>alert("hello")</script>." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3117
    "CrossSiteScripting_QUERYARGUMENTS",
    # AWS description: "Verifies that the request body size
    # is at most 10,240 bytes." For request details see issue:
    # https://github.com/18F/identity-devops/issues/3178
    "SizeRestrictions_BODY",
    # AWS description: "Inspects the value of the request body and blocks common
    # cross-site scripting (XSS) patterns using the built-in XSS detection
    # rule in AWS WAF. Example patterns include scripts like
    # <script>alert("hello")</script>."
    # Added during WAFv2 to prod, 2021-06-23
    "CrossSiteScripting_BODY",
  ]
}

variable "known_bad_input_ruleset_exclusions" {
  description = "List of rules to exclude for AWSManagedRulesKnownBadInputsRuleSet"
  type        = list(string)
  default     = []
}

variable "linux_ruleset_exclusions" {
  description = "List of rules to exclude for AWSManagedRulesLinuxRuleSet"
  type        = list(string)
  default     = []
}

variable "sql_injection_ruleset_exclusions" {
  description = "List of rules to exclude for AWSManagedRulesSQLiRuleSet"
  type        = list(string)
  default     = []
}

variable "otp_send_rate_limit_per_ip" {
  description = "OTP send rate limit per ip over 5 minutes, minimum value 100"
  type        = number
  default     = 100
}

variable "geo_block_list" {
  description = "Geographic Regions to block"
  type        = list(string)
  default     = []
}

variable "geo_us_regions" {
  description = <<EOM
Geographic Regions to block for EnforceCaptcha/EnforceChallenge WAF rules.
EOM
  type        = list(string)
  default     = ["US", "AS", "GU", "MP", "PR", "UM", "VI"]
}

# TODO: if possible, make more DRY and don't set here as well as
# in terraform/core and terraform/gitlab.
# Until then, these values MUST MATCH in the equivalent directories!

variable "header_block_regex" {
  description = "Map of regexes matching headers to block"
  type = list(object({
    field_name = string
    patterns   = list(string)
    }
    )
  )
  default = []
}

variable "waf_alert_blocked_period" {
  description = "Window (period) in seconds to for evaluating blocks"
  type        = string
  default     = "60"
}

variable "waf_alert_blocked_threshold" {
  description = "Alert threshold for number of blocks within waf_alert_blocked_period"
  type        = string
  default     = "5"
}

variable "rate_limit" {
  description = "Maximum number of requests from one IP allowed in a 5-minute period"
  type        = string
  default     = "5500"
}

variable "waf_alert_actions" {
  description = "List of SNS ARNs to deliver messages to upon alert"
  type        = list(string)
  default     = []
}

variable "ddos_alert_actions" {
  description = "List of SNS ARNs to deliver messages to upon DDOS alert"
  type        = list(string)
  default     = []
}

variable "soc_destination_arn" {
  description = "SOC destination ARN for WAF Logs"
  default     = "arn:aws:logs:us-west-2:752281881774:destination:elp-waf-lg"
}

variable "lb_name" {
  description = "LB on which to enforce WAF rules"
  default     = ""
}

variable "ship_logs_to_soc" {
  default = true
}

variable "restricted_paths_enforce" {
  description = "Count instead of Block excluded paths - ONLY USE IN SANDBOXES!"
  type        = bool
  default     = true
}

variable "geo_allow_list" {
  description = "List of codes of countries to permit access to via the WAFv2 ACL."
  type        = list(string)
  default = [
    "AS",
    "GU",
    "MP",
    "PR",
    "UM",
    "US",
    "VI",
  ]
}

variable "wafv2_web_acl_scope" {
  description = "Scope where rules are created, can be either REGIONAL or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"

  validation {
    condition = (
      var.wafv2_web_acl_scope == "REGIONAL" || var.wafv2_web_acl_scope == "CLOUDFRONT"
    )
    error_message = <<EOM
wafv2_web_acl_scope must be either set to either REGIONAL or CLOUDFRONT.
EOM
  }
}

variable "aws_shield_resources" {
  description = <<EOM
Map that contains resources to enable AWS Shield per environment.
Accepts a list of resource ARNs per resource type.
EOM
  type        = map(list(string))
  default = {
    cloudfront               = [],
    route53_hosted_zone      = [],
    global_accelerator       = [],
    application_loadbalancer = [],
    classic_loadbalancer     = [],
    elastic_ip_address       = []
  }
}

variable "automated_ddos_protection_action" {
  description = <<EOM
Value for the Automated Application Layer DDOS Mitigation setting for AWS Shield.
Valid values are Disable, Block, or Count.
EOM
  type        = string
  default     = "Disable"
  validation {
    condition = contains(
      ["Disable", "Block", "Count"],
      var.automated_ddos_protection_action
    )
    error_message = <<EOM
Shield_ddos action is not valid.
Valid options are 'Disable', 'Block', or 'Count'.
EOM
  }
}
