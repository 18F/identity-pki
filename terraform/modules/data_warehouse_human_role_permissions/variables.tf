variable "roles" {
  type        = list(string)
  description = "The list of roles to attach permissions to"
}

variable "permitted_regions" {
  type        = list(string)
  description = "A list of regions users are allowed to perform actions within"
  default = [
    "us-west-2"
  ]
}
