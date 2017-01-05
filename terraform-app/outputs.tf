output "env_name" {
  value = "${var.env_name}"
}

output "aws_db_address" {
  value = "postgres.login.gov.internal"
}

output "idp_db_address" {
  value = "idp-postgres.login.gov.internal"
}

output "aws_elasticache_cluster_address" {
  value = "redis.login.gov.internal"
}

output "app_eip" {
  value = "${aws_eip.app.public_ip}"
}

output "idp_worker_ip" {
  value = "${aws_instance.idp_worker.public_ip}"
}

output "idp_eip" {
  value = "${aws_eip.idp.public_ip}"
}

output "worker_ip" {
  value = "${aws_instance.worker.public_ip}"
}

output "jenkins_ip" {
  value = "${aws_instance.jenkins.public_ip}"
}

output "elk_ip" {
  value = "${aws_instance.elk.public_ip}"
}

output "jenkins" {
  value = "https://${aws_instance.jenkins.public_ip}:8443/"
}

output "elk" {
  value = "https://${aws_instance.elk.public_ip}:8443/"
}

output "chef-eip" {
  value = "${aws_eip.chef.public_ip}"
}

output "aws_vpc_id" {
  value = "VPC_ID=${aws_vpc.default.id}"
}

output "aws_sg_id" {
  value = "SECURITY_GROUP_ID=${aws_security_group.default.id}"
}

output "aws_app_subnet_id" {
  value = "SUBNET_ID=${aws_subnet.app.id}"
}

