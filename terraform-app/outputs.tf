output "env_name" {
  value = "${var.env_name}"
}

output "alb_hostname" {
  value = "${element(concat(aws_alb.idp.*.dns_name, list("")), 0)}"
}

output "aws_db_address" {
  value = "postgres.login.gov.internal"
}

output "aws_elasticache_cluster_address" {
  value = "redis.login.gov.internal"
}

output "aws_idp_sg_id" {
  value = "SECURITY_GROUP_ID=${aws_security_group.idp.id}"
}

output "elk" {
  value = "https://elk.login.gov.internal:8443/"
}

output "idp_db_address" {
  value = "idp-postgres.login.gov.internal"
}

output "jumphost-lb" {
  value = "${aws_route53_record.jumphost-elb-public.name}"
}

output "tlstest-cloudfront-domain" {
  value = "${element(concat(aws_cloudfront_distribution.tls_profiling.*.domain_name, list("")), 0)}"
}

output "snitest-cloudfront-domain" {
  value = "${element(concat(aws_cloudfront_distribution.sni_profiling.*.domain_name, list("")), 0)}"
}
