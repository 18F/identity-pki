variable "vpc_cidr" {
  description = "cidr block used by the VPC"
  default     = "10.65.0.0/16"
}

variable "auto_tf_fw_subnet_cidr" {
  description = "cidr block used by the network firewall"
  default     = "10.65.1.0/24"
}

variable "auto_tf_public_subnet_cidr" {
  description = "cidr block used by the subnet that talks to the world"
  default     = "10.65.3.0/24"
}

variable "auto_tf_private_subnet_cidr" {
  description = "cidr block used by the auto_terraform system to do terraform runs"
  default     = "10.65.6.0/24"
}

variable "auto_tf_vpcendpoints_subnet_cidr" {
  description = "cidr block used to house VPC endpoints"
  default     = "10.65.8.0/24"
}

variable "dns_domain" {
  description = "Domain to place all externally available tooling resources under"
  type        = string
  default     = "gitlab.identitysandbox.gov"
}

variable "region" {
  description = "AWS region, used for S3 bucket names"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "sandbox_account_id" {
  description = "account id for the sandbox account"
  default     = "894947205914"
}

variable "toolingprod_account_id" {
  description = "account id for the tooling prod account"
  default     = "217680906704"
}

variable "alpha_account_id" {
  description = "account id for the alpha account"
  default     = "917793222841"
}

variable "secopsdev_account_id" {
  description = "account id for the secopsdev account"
  default     = "138431511372"
}

variable "sms-sandbox_account_id" {
  description = "account id for the sms-sandbox account"
  default     = "035466892286"
}

output "auto_tf_vpc_id" {
  value = aws_vpc.auto_terraform.id
}

output "auto_tf_subnet_id" {
  value = aws_subnet.auto_terraform_private_a.id
}

output "auto_tf_subnet_arn" {
  value = aws_subnet.auto_terraform_private_a.arn
}

output "auto_tf_role_arn" {
  value = aws_iam_role.auto_terraform.arn
}

output "auto_tf_sg_id" {
  value = aws_security_group.auto_terraform.id
}

output "auto_tf_pipeline_role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}

output "auto_tf_bucket_id" {
  value = aws_s3_bucket.codepipeline_bucket.id
}

variable "events_sns_topic" {
  description = "name of the sns topic to send events to"
  default     = "slack-otherevents"
}

variable "privileged_cidr_blocks_v4" {
  type        = list(string)
  description = <<EOM
List of additional IPv4 CIDR blocks that should be allowed access 
through the WAFv2 web ACL(s) to restricted endpoints.
EOM
  default = [
    "159.142.0.0/16", # GSA VPN IPs
  ]
}

variable "privileged_cidr_blocks_v6" {
  type        = list(string)
  description = <<EOM
List of additional IPv6 CIDR blocks that should be allowed access
through the WAFv2 web ACL(s) to restricted endpoints.
EOM
  default     = []
}
