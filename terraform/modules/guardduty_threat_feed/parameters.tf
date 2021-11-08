resource "aws_ssm_parameter" "guardduty_threat_feed_public_key" {
  name        = "${var.guardduty_threat_feed_name}-public-key"
  description = "Guard Duty Threat Feed 3rd party public key"
  type        = "SecureString"
  value       = "pub-test" # Manually update via aws ssm put-parameter after deploying
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "guardduty_threat_feed_private_key" {
  name        = "${var.guardduty_threat_feed_name}-private-key"
  description = "Guard Duty Threat Feed 3rd party private key"
  type        = "SecureString"
  value       = "priv-test" # Manually update via aws ssm put-parameter after deploying
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}