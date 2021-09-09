locals {
  web_acl_name = "${var.env}-idp-waf"
}

variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "env" {
  description = "Environment name"
}

variable "enforce" {
  description = "Set to true to enforce WAF ACL rules or false to just count traffic matching rules"
  type        = bool
  default     = false
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
    # AWS description: "Inspects the values of the request body and blocks requests attempting to 
    # exploit RFI (Remote File Inclusion) in web applications. Examples include patterns like ://."
    # For request details see issue https://github.com/18F/identity-devops/issues/3085
    "GenericRFI_BODY",
    # AWS description: "Inspects the values of all query parameters and blocks requests attempting to 
    # exploit RFI (Remote File Inclusion) in web applications. Examples include patterns like ://."
    # For request details see issue https://github.com/18F/identity-devops/issues/3100
    "GenericRFI_QUERYARGUMENTS",
    # AWS description: "Verifies that the URI query string length is within the standard boundary for applications."
    # For request details see issue https://github.com/18F/identity-devops/issues/3100
    "SizeRestrictions_QUERYSTRING",
    # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata from the request query arguments."
    # For request details see issue https://github.com/18F/identity-devops/issues/3100
    "EC2MetaDataSSRF_QUERYARGUMENTS",
    # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata from the request cookie."
    # For request details see issue https://github.com/18F/identity-devops/issues/3100
    "EC2MetaDataSSRF_BODY",
    # AWS description: "Blocks requests with no HTTP User-Agent header."
    # For request details see issue https://github.com/18F/identity-devops/issues/3100
    "NoUserAgent_HEADER",
    # AWS description: "Inspects the value of query arguments and blocks common cross-site
    # scripting (XSS) patterns using the built-in XSS detection rule in AWS WAF.
    # Example patterns include scripts like <script>alert("hello")</script>."
    # For request details see issue https://github.com/18F/identity-devops/issues/3117
    "CrossSiteScripting_QUERYARGUMENTS",
    # AWS description: "Verifies that the request body size is at most 10,240 bytes."
    # For request details see issue https://github.com/18F/identity-devops/issues/3178
    "SizeRestrictions_BODY",
    # AWS description: "Inspects the value of the request body and blocks common cross-site
    # scripting (XSS) patterns using the built-in XSS detection rule in AWS WAF.
    # Example patterns include scripts like <script>alert("hello")</script>."
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

variable "ip_block_list" {
  description = "IP addresses to block"
  type        = list(string)
  default     = []
}

variable "waf_alert_blocked_period" {
  description = "Window (period) in seconds to for evaluating blocks"
  type        = string
  default     = "60"
}

variable "waf_alert_blocked_threshold" {
  description = "Alert will fire if the number of blocks within the window is >= this value"
  type        = string
  default     = "5"
}

variable "waf_alert_actions" {
  description = "List of SNS ARNs to deliver messages to upon alert"
  type        = list(string)
  default     = []
}

