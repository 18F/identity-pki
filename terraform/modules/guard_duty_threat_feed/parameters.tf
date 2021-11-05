resource "aws_ssm_parameter" "guard_duty_threat_feed_public_key" {
  name        = "${var.guard_duty_threat_feed_name}-public-key"
  description = "Guard Duty Threat Feed 3rd party public key"
  type        = "SecureString"
  value       = var.guard_duty_threat_feed_public_key
}

resource "aws_ssm_parameter" "guard_duty_threat_feed_private_key" {
  name        = "${var.guard_duty_threat_feed_name}-private-key"
  description = "Guard Duty Threat Feed 3rd party private key"
  type        = "SecureString"
  value       = var.guard_duty_threat_feed_private_key
}