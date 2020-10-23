variable "opsgenie_key_file" {
  description = "the name of the file in the secrets/common bucket to use for sending opsgenie alerts for this environment"
  default = "opsgenie_low_apikey"
}

variable "staticsite_alerts_enabled" {
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

variable "enduser_enabled" {
  description = "set this to 1 if you want to enable enduser alerting"
  default = 0
}

variable "dashboard_enabled" {
  description = "set this to 1 if you want to alert during business hours on dashboard problems"
  default = 0
}

variable "env_name" {}

variable "region" {
  default = "us-west-2"
}

variable "ten_min_alert_events" {
  default = 4000
}

variable "pivcac_alert_threshold" {
  description = "If the number of queries to the pivcac services in 5 minutes falls below this number, we alert."
  default = 20
}

variable "apdex_alert_threshold" {
  description = "If the apdex falls below this number for 5 minutes, we alert."
  default = 0.8
}

variable "error_alert_threshold" {
  description = "If the error rate goes above this percentage rate for 5 minutes, we alert.  Default is 5%"
  default = 5
}

variable "error_warn_threshold" {
  description = "If the error rate goes above this percentage rate for 5 minutes, we warn.  Default is 3.5%"
  default = 3.5
}

variable "web_alert_threshold" {
  description = "If the number of queries in 5 minutes to the main app falls below this number, we alert"
  default = 300
}

variable "web_warn_threshold" {
  description = "If the number of queries in 15 minutes to the main app falls below this number, we warn"
  default = 475
}

variable "response_time_alert" {
  description = "If the response time is above this number (seconds) on the average over the course of 5 minutes, alert"
  default = 2
}

variable "response_time_warn" {
  description = "If the response time is above this number (seconds) on the average over the course of 5 minutes, warn"
  default = 1
}

variable "datastore_alert_threshold" {
  description = "If any datastore query latency is above this (seconds?), alert"
  default = 2
}

variable "datastore_warn_threshold" {
  description = "If any datastore query latency is above this (seconds?), warn"
  default = 1
}

variable "root_domain" {
  description = "the domain under which the environment lives under"
}

variable "error_dashboard_site" {
  description = "The name of the newrelic app name to put on the error dashboard"
  default = "prod.login.gov"
}
