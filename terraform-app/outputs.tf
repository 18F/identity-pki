output "aws_db_address" {
  value = "${aws_db_instance.default.address}"
}

# output "aws_db_password" {
#   value = "${aws_db_instance.default.rds_password}"
# }

# output "aws_db_address" {
#   value = "${aws_db_instance.default.rds_username}"
# }

output "aws_elasticache_cluster_address" {
  value = "${aws_elasticache_cluster.app.cache_nodes.0.address}"
}

output "aws_instance_app_public_ip" {
  value = "${aws_instance.app.public_ip}"
}

output "aws_eip_app_public_ip" {
  value = "${aws_eip.app.public_ip}"
}

output "aws_instance_worker_public_ip" {
  value = "${aws_instance.worker.public_ip}"
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
