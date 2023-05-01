resource "aws_ssm_parameter" "salesforce_instance_url" {
  name        = "/account/salesforce/instance_url"
  type        = "SecureString"
  description = "URL to the SalesForce instance used by SalesForce CLI tools"
  value       = "UNSET"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "salesforce_client_id" {
  name        = "/account/salesforce/client_id"
  type        = "SecureString"
  description = "Client ID for use with SalesForce CLI tools"
  value       = "UNSET"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "salesforce_client_secret" {
  name        = "/account/salesforce/client_secret"
  type        = "SecureString"
  description = "Secret for use with SalesForce CLI tools"
  value       = "UNSET"
  lifecycle {
    ignore_changes = [value]
  }
}

