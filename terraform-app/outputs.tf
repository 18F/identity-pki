output "aws_db_address_app" {
  value = "${aws_db_instance.app.address}"
}

output "aws_db_address_idp" {
  value = "postgres.login.gov.internal"
}

output "aws_elasticache_cluster_address" {
  value = "redis.login.gov.internal"
}

output "app_ip" {
  value = "${aws_eip.app.public_ip}"
}

output "aws_app_subnet_id" {
  value = "SUBNET_ID=${aws_subnet.app.id}"
}

output "aws_eip_app_public_ip" {
  value = "${aws_eip.app.public_ip}"
}

output "aws_eip_idp_public_ip" {
  value = "${aws_eip.idp.public_ip}"
}

output "idp_worker_ip" {
  value = "${aws_instance.idp_worker.public_ip}"
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

output "aws_instance_idp_worker_public_ip" {
  value = "${aws_instance.idp_worker.public_ip}"
}

output "aws_sg_id" {
  value = "SECURITY_GROUP_ID=${aws_security_group.default.id}"
}

output "aws_vpc_id" {
  value = "VPC_ID=${aws_vpc.default.id}"
}

output "chef-eip" {
  value = "${aws_eip.chef.public_ip}"
}

output "elk" {
  value = "https://${aws_instance.elk.public_ip}:8443/"
}

output "jenkins" {
  value = "https://${aws_instance.jenkins.public_ip}:8443/"
}
