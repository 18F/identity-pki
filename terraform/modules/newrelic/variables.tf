
variable "enabled" {}

variable "env_name" {}

variable "region" {
  default = "us-west-2"
}

variable "events_in_last_ten_minutes_threshold" {
  default = 4000
}
