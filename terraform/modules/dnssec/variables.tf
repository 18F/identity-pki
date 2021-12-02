variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

variable "dnssec_ksk_max_days" {
  description = "Maxium age of DNSSEC KSK before alerting due to being too old"
  type        = number
  default     = 366
}

variable "dnssec_ksks" {
  description = "Map of Key Signing Keys (KSKs) to provision for each zone"
  # This can be used to perform key rotation.  For example, if you
  # start with this map:
  #  dnssec_ksks = { "20210808" = "active"}
  # One key will be provisioned and its DS value will be returned as output
  #
  # Later, a rotation can be performed:
  #  dnssec_ksks = { "20210808" = "old", "20220208" = "active"}
  #
  # This will create key "20220208" and set it as the active key for DS
  # output, but leave the old key in place.
  #
  # THE DS RECORD MUST BE UPDATED TO THE NEW ACTIVE KEY'S VALUE!
  # See https://github.com/18F/identity-devops/wiki/Runbook:-DNS#ksk-rotation
  #
  # Finally, once the TTL*2 has passed for all DS records referencing
  # the old key, it can be removed.  MAKE SURE THE OLD DS IS GONE BEFORE
  # THIS CHANGE:
  #  dnssec_ksks = { "20220208" = "active"}
  type = map(string)
  default = {
    # "2111005" = "old",
    "20211006" = "active"
  }
}

variable "dnssec_zone_name" {
  description = "Name of the Route53 DNS domain to to apply DNSSEC configuration to."
  type        = string
}

variable "dnssec_zone_id" {
  description = "ID of the Route53 DNS domain to to apply DNSSEC configuration to."
  type        = string
}
