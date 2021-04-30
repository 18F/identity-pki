variable "opsgenie_key_file" {
  description = "the name of the file in the secrets/common bucket to use for sending opsgenie alerts for this environment"
  default     = "opsgenie_low_apikey"
}

variable "enabled" {
  description = "turn on common newrelic alerting services"
  default     = 0
}

variable "staticsite_alerts_enabled" {
  description = "this should only be set in the prod environment, as it creates monitors for the static site"
  default     = 0
}

variable "elk_enabled" {
  description = "set this to 1 if you want to alert on ELK problems"
  default     = 0
}

variable "idp_enabled" {
  description = "set this to 1 if you want to alert on idp problems"
  default     = 0
}

variable "enduser_enabled" {
  description = "set this to 1 if you want to enable enduser alerting"
  default     = 0
}

variable "dashboard_enabled" {
  description = "set this to 1 if you want to alert during business hours on dashboard problems"
  default     = 0
}

variable "pivcac_service_enabled" {
  description = "set this to 1 if you want to alert during business hours on pivcac problems"
  default     = 0
}

variable "env_name" {}

variable "region" {
  default = "us-west-2"
}

variable "events_in_last_ten_minutes_alert_threshold" {
  default = 4000
}

variable "apdex_alert_threshold" {
  description = "If the apdex falls below this number for 5 minutes, we alert."
  default     = 0.8
}

variable "error_alert_threshold" {
  description = "If the error rate goes above this percentage rate for 5 minutes, we alert.  Default is 5%"
  default     = 5
}

variable "error_warn_threshold" {
  description = "If the error rate goes above this percentage rate for 5 minutes, we warn.  Default is 3.5%"
  default     = 3.5
}

variable "web_low_traffic_alert_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we alert"
  default     = 10
}

variable "web_low_traffic_warn_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we warn"
  default     = 20
}

variable "pivcac_low_traffic_alert_threshold" {
  description = "If the number of queries in 5 minutes falls below this number, we alert"
  default     = 5
}

variable "response_time_alert" {
  description = "If the response time is above this number (seconds) on the average over the course of 5 minutes, alert"
  default     = 2
}

variable "response_time_warn" {
  description = "If the response time is above this number (seconds) on the average over the course of 5 minutes, warn"
  default     = 1
}

variable "datastore_alert_threshold" {
  description = "If any datastore query latency is above this (seconds?), alert"
  default     = 2
}

variable "datastore_warn_threshold" {
  description = "If any datastore query latency is above this (seconds?), warn"
  default     = 1
}

variable "root_domain" {
  description = "the domain under which the environment lives under"
}

variable "error_dashboard_site" {
  description = "The name of the newrelic app name to put on the error dashboard"
  default     = "prod.login.gov"
}

variable "staticsite_fixed_string" {
  description = "Text that must be in the response for all monitored static sites"
  type        = string
  # The following should be set in the login.gov brochure site at all times:
  #  <meta sys-status="login.gov site up and running">
  default = "login.gov site up and running"
}
