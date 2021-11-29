variable "config_access_key_rotation_name" {
  description = "Name of the Config access key rotation, used to name other resources"
  type        = string
  default     = "cfg-access-key-rotation"
}

variable "region" {
  default = "us-west-2"
}

variable "config_access_key_rotation_frequency" {
  type        = string
  description = "The frequency that you want AWS Config to run evaluations for the rule."
  default     = "Six_Hours"
}

variable "config_access_key_rotation_max_key_age" {
  type        = string
  description = "Maximum number of days without rotation. Default 90."
  default     = 90
}

variable "config_access_key_rotation_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/config-access-key-rotation.zip"
}

variable "slack_events_sns_topic" {
  type        = string
  description = "Name of the SNS topic for slack."
  default     = "slack-otherevents"
}