
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

# notification_state values can be ENABLED or DISABLED
# authentication_type can be either API_KEY or BASIC
variable "risc_notifications" {
  type = map(object({
    partner_name            = string
    notification_url        = string
    notification_rate_limit = number
    notification_source     = string
    notification_state      = string
    authentication_type     = string
    basic_auth_user_name    = string
    api_key_name            = string
  }))
  default = {
    test_destination = {
      partner_name            = "test-risc"
      notification_url        = "https://q8zvrjf2kc.execute-api.us-west-2.amazonaws.com/test/postmessage"
      notification_rate_limit = 10
      notification_source     = "risc.notifications.crissupb"
      notification_state      = "ENABLED"
      basic_auth_user_name    = "na"
      api_key_name            = "x-api-key"
      authentication_type     = "API_KEY"
    }
  }
}