resource "aws_s3_bucket_object" "packer_config" {
  for_each = toset(var.ami_types)

  bucket       = var.artifact_bucket
  key          = "packer_config/${local.aws_alias}/${each.key}.18.json"
  content      = <<JSON
{
  "aws_access_key": "",
  "aws_secret_key": "",
  "aws_region": "${var.region}",
  "encryption": "${var.packer_config["encryption"]}",
  "root_vol_size": "${var.packer_config["root_vol_size"]}",
  "data_vol_size": "${var.packer_config["data_vol_size"]}",
  "security_group_id": "${aws_cloudformation_stack.image_network_stack.outputs["PublicSecurityGroupId"]}",
  "vpc_id": "${aws_cloudformation_stack.image_network_stack.outputs["VPCID"]}",
  "subnet_id": "${aws_cloudformation_stack.image_network_stack.outputs["PublicSubnet1ID"]}",
  "deregister_existing_ami": "${var.packer_config["deregister_existing_ami"]}",
  "delete_ami_snapshots": "${var.packer_config["delete_ami_snapshots"]}",
  "ami_name": "login.gov ${each.key} role hardened image ${var.packer_config["os_version"]}",
  "ami_description": "CIS hardened image based on ${var.packer_config["os_version"]}",
  "chef_role": "${each.key}",
  "chef_version": "${var.packer_config["chef_version"]}",
  "os_version": "${var.packer_config["os_version"]}",
  "ami_owner_id": "${var.packer_config["ami_owner_id"]}",
  "ami_filter_name": "${var.packer_config["ami_filter_name"]}"
}
JSON
  content_type = "text/plain"
}
