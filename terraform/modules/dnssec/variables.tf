variable "root_zone_id" {
  description = "ID of the root zone in Route53."
  type        = string
}

variable "root_zone_id" {
  description = "Name of the root zone in Route53."
  type        = string
}

variable "dnssec_ksks" {
  description = "Map of Key Signing Keys to provision for each zone"
  # This can be used to perform key rotation.  For example, if you
  # start with this map:
  #  dnssec_ksks = { "20210808" = "Key A", "20210809" = "Key B"}
  # Two keys will be provisioned.  In 6 months you can update the map to:
  #  dnssec_ksks = { "20210809" = "Key B", "20220209" = "Key C"}
  # This will decommission "Key A" but leave "Key B" intact.  "Key C"
  # will be added and propagated.  Remember that the registrar must
  # be updated to remove the old and add the new keys!
  type    = map(string)
  default = {
    "20211005" = "red",
    "20211006" = "green",
  #  "20210406" = "blue"
  }
}

variable "alarm_actions" {
  description = "List of actions to trigger on transition between OK and ALARM states"
  # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html#alarms-and-actions
  # for more on the types of actions.
  type    = list(string)
  default = []
}

variable "default_ttl" {
  description = "Default TTL for records"
  type        = string
  default     = "300"
}

variable "dnssec_ksk_max_age_days" {
  description = "Maxium age of DNSSEC KSK before alerting due to being too old"
  type        = number
  default     = 366
}

variable "region" {
  description = "AWS region to create resources in by default"
  type        = string
  default     = "us-east-1"
}

variable "domain" {
  description = "Top level DNS zone name"
}

variable "static_records" {
  description = "List of additional resource records to manage for zone"
  type = list(object({
    name    = string,
    type    = string,
    ttl     = optional(string),
    records = list(string)
  }))
  # Each entry is a map with a name, type, and list of records (values)
  # You can supply and optional TTL.
  #
  # Example:
  # static_rrs = [
  #   {
  #     name = "donuts",
  #     type = "A",
  #     ttl  = "300",
  #     records = [
  #       "1.2.3.4"
  #     ]
  #   },
  #   {
  #     name    = "fritters",
  #     type    = "CNAME",
  #     records = ["donuts.fqdn."],
  #   },
  #     # Record with name of root and the default ttl
  #     name    = "",
  #     type    = "A",
  #     records = ["10.11.12.14"]
  # ]
  default = []
}
