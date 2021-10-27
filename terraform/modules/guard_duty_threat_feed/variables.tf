variable "guard_duty_threat_feed_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "days_requested" {
  type    = number
  default = 7
}

variable "frequency" {
  type    = number
  default = 6
}

variable "guard_duty_threat_feed_public_key" {
  type        = string
  description = "Enter the public key value contents (This will be stored in a secured parameter store)"
}

variable "guard_duty_threat_feed_private_key" {
  type        = string
  description = "Enter the private key value contents (This will be stored in a secured parameter store)"
}

variable "guard_duty_threat_feed_code" {
  type        = string
  description = "Enter the path of the compressed lambda source code. e.g: (../guard/src/guard-duty-threat-feed.zip)"
}