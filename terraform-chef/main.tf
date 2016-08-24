provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_eip" "chef" {
  instance = "${aws_instance.chef.id}"
  vpc      = true
}

resource "aws_instance" "chef" {
  ami = "${var.chef_ami_id}"
  depends_on = ["aws_internet_gateway.default"]
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "login-chef"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]
}
