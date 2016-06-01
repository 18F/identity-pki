provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "web" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default"]
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]
}
