variable "network_acl_id" {
    description = "ID of the NACL to attach these rules to."
}

variable "ssh_cidr_blocks" {
    description = "CIDR blocks to allow into this NACL."
    default = []
}

variable "enabled" {
    description = "Whether to create these NACL rules.  Workaround for the fact that count doesn't work for modules."
    default = 1
}
