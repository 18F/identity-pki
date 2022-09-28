output "env_name" {
  value = var.env_name
}

output "alb_hostname" {
  value = element(concat(aws_alb.idp.*.dns_name, [""]), 0)
}

output "aws_db_address" {
  value = "postgres.login.gov.internal"
}

output "aws_elasticache_cluster_address" {
  value = aws_elasticache_replication_group.idp.primary_endpoint_address
}

output "aws_elasticache_cluster_attempts_address" {
  value = aws_elasticache_replication_group.idp_attempts.primary_endpoint_address
}

output "aws_idp_sg_id" {
  value = "SECURITY_GROUP_ID=${aws_security_group.idp.id}"
}

output "idp_db_address" {
  value = "idp-postgres.login.gov.internal"
}

output "jumphost-lb" {
  value = aws_route53_record.jumphost-elb-public.name
}

output "idp_dns_name" {
  value = aws_route53_record.c_cloudfront_idp.fqdn
}

output "idp_origin_dns_name" {
  value = aws_route53_record.origin_alb_idp.fqdn
}

output "region" {
  value = var.region
}

output "idp_custom_pages" {
  description = "List of custom error pages served up by cloudfront"
  value = [
    for k, v in var.cloudfront_custom_pages : "https://${aws_route53_record.c_cloudfront_idp.fqdn}/${k}"
  ]
}
