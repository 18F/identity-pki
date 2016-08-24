output "aws_eip_public_ip" {
  value = "${aws_eip.chef.public_ip}"
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
