
variable "enabled" {
  description = "turn on common newrelic alerting services"
}

variable "www_enabled" {
  description = "this should only be set in the prod environment, as it creates monitors for the static site"
  default = 0
}

variable "elk_enabled" {
  description = "set this to 1 if you want to alert on ELK problems"
  default = 0
}

variable "idp_enabled" {
  description = "set this to 1 if you want to alert on idp problems"
  default = 0
}

variable "env_name" {}

variable "region" {
  default = "us-west-2"
}

variable "events_in_last_ten_minutes_threshold" {
  default = 4000
}

variable "pivcac_threshold" {
  description = "If the number of queries to the pivcac services in 5 minutes falls below this number, we alert."
  default = 20
}

variable "web_threshold" {
  description = "If the number of queries in 5 minutes to the main app falls below this number, we alert"
  default = 300
}

variable "web_warn_threshold" {
  description = "If the number of queries in 15 minutes to the main app falls below this number, we warn"
  default = 475
}

variable "root_domain" {
  description = "the domain under which the environment lives under"
}
