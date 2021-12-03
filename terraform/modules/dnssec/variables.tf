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
  # This can be used to perform key rotation following the notes in
  # https://github.com/18F/identity-devops/wiki/Runbook:-DNS#ksk-rotation
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
