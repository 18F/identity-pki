locals {
  resource_name_split = split("/",var.resource_arn)
  resource_name_split_length = length(local.resource_name_split)
  resource_name = element(local.resource_name_split,local.resource_name_split_length - 1)
  status_file_name = ".aws_shield_${local.resource_name}_status.txt"
}

resource "null_resource" "test_parameters" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "resource_arn: ${var.resource_arn} - resource_name: ${local.resource_name} - action: ${var.action}" > ~/testParameters.txt
    EOT
  }
}

# Null resource to determine current state of AWS Shield Automatic DDOS Protection of the passed ARN
# TODO: Change from admin account to terraform. Requires AWS Permission changes.

resource "null_resource" "get_shield_autoddos_status" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      shield_status=`aws shield list-protections --inclusion-filters ResourceArns="${var.resource_arn}" --query 'Protections[*].ApplicationLayerAutomaticResponseConfiguration[].Action' --output json | tr -d ':"[]{}[:space:]'`; if [ -z "$shield_status" ]; then echo "Disable" > ${path.module}/${local.status_file_name}; else echo $shield_status > ${path.module}/${local.status_file_name}; fi
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
resource "null_resource" "update_shield_autoddos" {
  depends_on = [ 
    null_resource.get_shield_autoddos_status
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      current_action=`echo ${data.local_file.current_action.content} | tr -d '\n'`; if [ "${var.action}" != "$current_action" ]; then aws shield ${var.action == "Disable" ? "disable" : (chomp(data.local_file.current_action.content) == "Disable" ? "enable" : "update")}-application-layer-automatic-response --resource-arn "${var.resource_arn}"${var.action_command[var.action]}; else echo "No action necessary"; fi
    EOT
  }
}
