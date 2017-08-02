output "env_name" {
  value = "${var.env_name}"
}

output "alb_hostname" {
  value = "${aws_alb.idp.dns_name}"
}

output "app_eip" {
  value = "${aws_eip.app.public_ip}"
}

output "aws_app_subnet_id" {
  value = "SUBNET_ID=${aws_subnet.app.id}"
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

output "jenkins" {
  value = "https://jenkins.login.gov.internal:8443/"
}

output "elk" {
  value = "https://elk.login.gov.internal:8443/"
}

output "elk_ip" {
  value = "${var.non_asg_elk_enabled == 1 ? aws_instance.elk.public_ip : 0}"
}

output "idp1_eips" {
  value = ["${var.non_asg_idp_enabled == 1 ? aws_instance.idp1.*.public_ip : 0}"]
}

output "idp2_eips" {
  value = ["${var.non_asg_idp_enabled == 1 ? aws_instance.idp2.*.public_ip : 0}"]
}

output "idp_db_address" {
  value = "idp-postgres.login.gov.internal"
}

output "idp_tls_common_name" {
  value = "${acme_certificate.idp.certificate_domain}"
}

output "idp_worker_ips" {
  value = ["${var.non_asg_idp_worker_enabled == 1 ? aws_instance.idp_worker.*.public_ip : 0}"]
}

output "jumphost-eip" {
  value = "${var.non_asg_jumphost_enabled == 1 ? aws_eip.jumphost.public_ip : 0}"
}

output "jumphost-command" {
  value = "ssh -L3128:localhost:3128 -A ${var.non_asg_jumphost_enabled == 1 ? aws_eip.jumphost.public_ip : 0}"
}
