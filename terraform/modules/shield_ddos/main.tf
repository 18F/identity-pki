data "aws_arn" "resource" {
  arn = var.resource_arn
}

locals {
  resource_name_split = split("/",data.aws_arn.resource.resource)
  resource_name_split_length = length(local.resource_name_split)
  resource_name = element(local.resource_name_split,local.resource_name_split_length - 1)
  status_file_name = ".aws_shield_${local.resource_name}_status.txt"
  waf_file_name = ".aws_webaclid_${local.resource_name}.txt"
}

# Null resource to determine current state of AWS Shield Automatic DDOS Protection of the passed ARN. Result is stored in hidden file to be used later.
# AWS Command to get the current state must return as json output and then formatted to remove unnecessary characters.
# This is due to current text output not providing the Action field.
# If the result is null, it means that Automatic DDOS Protection is currently disabled for the selected resource. In this case, the result is altered from a null value to "Disable" for ease of future conditional checks.
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

# Null resource to determine if the associated CloudFront resource is associated to a WebACL. Result is stored in hidden file to be used later.
resource "null_resource" "get_cloudfront_waf" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      aws cloudfront get-distribution-config --id ${local.resource_name} --query 'DistributionConfig.WebACLId' --output text > ${path.module}/${local.waf_file_name}
    EOT
  }
}

#Setup access to content of hidden files created in previous steps
data "local_file" "current_action" {
  depends_on = [
    null_resource.get_shield_autoddos_status
  ]
  filename = "${path.module}/${local.status_file_name}"
}

data "local_file" "web_acl_id" {
  depends_on = [
    null_resource.get_cloudfront_waf
  ]
  filename = "${path.module}/${local.waf_file_name}"
}

# Null resource that builds and runs appropriate AWS Shield command based on current_action, cloudfront web_acl_id, and selected action. 
# Actions can be 'Disable', 'Count', or 'Block'. Disable turns off automated DDOS protection. Count turns it on, but instead of blocking violating traffic, counts it. Block prevents access to the ClouFront resource for violating traffic.
# If the current_action matches the selected action, the command will echo out "No action necessary". If the cloudfront web_acl_id is null, the command will echo out "No action necessary" because a web_acl_id is required to enabled automated DDOS protection. 
# If the current_action and selected action are different and a web_acl_id exists, then an AWS shield command is built based on the selected action. 
# The three potential commands are:
#   disable-application-layer-automatic-response
#   enable-application-layer-automatic-response
#   update-application-layer-automatic-response
# The Enable and Update commands will also be appended with the applicable command suffix to set the automated DDOS protection action to either Block or Count.
resource "null_resource" "update_shield_autoddos" {
  depends_on = [ 
    data.local_file.current_action,
    data.local_file.web_acl_id
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    
    command = <<EOT
      if [ "${var.action}" != "${chomp(data.local_file.current_action.content)}" ] && [ "${chomp(data.local_file.web_acl_id.content)}" != ""  ]; then aws shield ${var.action == "Disable" ? "disable" : (chomp(data.local_file.current_action.content) == "Disable" ? "enable" : "update")}-application-layer-automatic-response --resource-arn "${var.resource_arn}"${var.action_command[var.action]}; else echo "No action necessary"; fi
    EOT
  }
}
