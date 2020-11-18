# Creates parameters but you need to set the values!
# Only parameters used by all IdP functions should be included

resource "aws_ssm_parameter" "idp_function_parameters" {
  for_each = var.idp_function_parameters

  name        = "/${var.env_name}/idp/functions/${each.key}"
  description = each.value
  type        = "SecureString"
  overwrite   = false
  value       = "Starter value"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
