output "privileged_cidrs_v4" {
  description = "IPv4 CIDR blocks to allow through the WAFv2 web ACL(s)."
  value = length(local.privileged_cidrs_v4) > 0 ? sort(
    aws_wafv2_ip_set.privileged_ips_v4[0].addresses
  ) : []
}

output "privileged_cidrs_v6" {
  description = "IPv6 CIDR blocks to allow through the WAFv2 web ACL(s)."
  value = length(local.privileged_cidrs_v6) > 0 ? sort(
    aws_wafv2_ip_set.privileged_ips_v6[0].addresses
  ) : []
}

output "block_list_v4" {
  description = "IPv4 addresses with CIDR masks to block in the WAFv2 web ACL(s)."
  value = length(var.ip_block_cidrs_v4) > 0 ? sort(
    aws_wafv2_ip_set.block_list_v4[0].addresses
  ) : []
}

output "block_list_v6" {
  description = "IPv6 addresses with CIDR masks to block in the WAFv2 web ACL(s)."
  value = length(var.ip_block_cidrs_v6) > 0 ? sort(
    aws_wafv2_ip_set.block_list_v6[0].addresses
  ) : []
}
