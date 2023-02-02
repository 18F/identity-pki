#TODO: Variables needed - acctType, resourceArn, action, resourceName
locals {
  status_file_name = "aws_shield_${resourceName}_status.txt"
  resource_name = element(split("/",var.resource_arn),length(split("/",var.resource_arn)-1))
}

resource "null_resource" "test_parameters" {
  provisioner "local-exec" {
    command = <<EOT
      echo "acctType: ${var.acctType} - resource_arn: ${resource_arn} - resource_name: ${resource_name} - action: ${action}" << ~/testParameters.txt
    EOT
  }
}

# Null resource to determine current state of AWS Shield Automatic DDOS Protection of the passed ARN
# TODO: Change from admin account to terraform. Requires AWS Permission changes.

resource "null_resource" "get_shield_autoddos_status" {
  provisioner "local-exec" {
    command = <<EOT
      aws-vault exec ${var.acctType}-admin -- aws shield list-protections --inclusion-filters ResourceArns="${var.resource_arn}" --query 'Protections[*].ApplicationLayerAutomaticResponseConfiguration[].Action' --output json | tr -d ':"[]{}[:space:]' >> ${path.modules}/${local.status_file_name}
    EOT
  }
}

data "local_file" "current_action" {
  depends_on = [
    null_resource.get_shield_autoddos_status
  ]
  filename = "${path.module}/${local.status_file_name}"
}

# Logic:
# If action = current status. Do nothing
# Then, if action = disable. Run block disabling
#       if action = count or block and status is null, run enable block with action in the command
#       if action = count or block and status is not null, run the update block with action in the command
resource "null_resource" "disable_shield_autoddos" {
  count = var.action == "Disable" && data.local_file.current_action.content != "" ? 1 : 0
  command = <<EOT
    aws-vault exec ${var.acctType}-admin -- aws shield disable-application-layer-automatic-response --resource-arn "${var.resource_arn}"
  EOT
}

resource "null_resource" "enable_shield_autoddos" {
  count = var.action != "Disable" && data.local_file.current_action.content == "" ? 1 : 0
  command = <<EOT
    aws-vault exec ${var.acctType}-admin -- aws shield enable-application-layer-automatic-response --resource-arn "${var.resource_arn}" --action "${var.action}={}"
  EOT
}

resource "null_resource" "update_shield_autoddos" {
  count = var.action != "Disable" && data.local_file.current_action.content != "" && var.action != data.local_file.current_status.content ? 1 : 0
  command = <<EOT
    aws-vault exec ${var.acctType}-admin -- aws shield update-application-layer-automatic-response --resource-arn "${var.resource_arn}" --action "${var.action}={}"
  EOT
}
