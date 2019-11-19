resource "aws_cloudwatch_log_group" "kms_log" {
    name = "${var.env_name}_/srv/idp/shared/log/kms.log"

    tags = {
        environment = "${var.env_name}"
    }
}

resource "aws_cloudwatch_log_group" "squid_access_log" {
    name = "${var.env_name}_/var/log/squid/access.log"

    tags = {
        environment = "${var.env_name}"
    }
}
