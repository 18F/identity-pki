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
  #  dnssec_ksks = { "20210808" = "Key A", "20210809" = "Key B"}
  # Two keys will be provisioned.  In 6 months you can update the map to:
  #  dnssec_ksks = { "20210809" = "Key B", "20220209" = "Key C"}
  # This will decommission "Key A" but leave "Key B" intact.  "Key C"
  # will be added and propagated.  Remember that the registrar must
  # be updated to remove the old and add the new keys!
  type = map(string)
  default = {
    # "20211005" = "red",
    "20211006" = "green",
    # "20210406" = "blue"
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
