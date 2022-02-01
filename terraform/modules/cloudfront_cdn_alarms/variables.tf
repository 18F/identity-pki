variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the alarms fire"
}

variable "distribution_name" {
  type        = string
  description = "Name of CloudFront Distribution"
}

variable "threshold" {
  type        = number
  description = "Threshold to alert on"
}

variable "dimensions" {
  type        = map(string)
  description = "Cloudfront Alarm dimensions"
}

variable "env_name" {
  type        = string
  description = "Name of Environment"
}
