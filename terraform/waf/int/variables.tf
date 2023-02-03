variable "partner_ip_list_of_shame" {
  description = "A list of CIDRs for partners that want to beat up poor Mr. Int"
  type        = list(string)
  default = [
    "18.213.100.122/32" # SAM.gov likes to load test using Int :(
  ]
}
