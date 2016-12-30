output "aws_db_address_app" {
  value = "${aws_db_instance.app.address}"
}

output "aws_db_address_idp" {
  value = "${aws_db_instance.idp.address}"
}

output "aws_elasticache_cluster_address" {
  value = "${aws_elasticache_cluster.idp.cache_nodes.0.address}"
}

output "aws_instance_app_public_ip" {
  value = "${aws_instance.app.public_ip}"
}

output "aws_instance_idp_public_ip" {
  value = "${aws_instance.idp.public_ip}"
}

output "aws_instance_idp_worker_public_ip" {
  value = "${aws_instance.idp_worker.public_ip}"
}

output "aws_eip_app_public_ip" {
  value = "${aws_eip.app.public_ip}"
}

output "aws_eip_idp_public_ip" {
  value = "${aws_eip.idp.public_ip}"
}

output "aws_vpc_cidr_block" {
  value = "${aws_vpc.default.cidr_block}"
}

output "aws_vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "aws_vpc_route_table_id" {
  value = "${aws_vpc.default.main_route_table_id}"
}
