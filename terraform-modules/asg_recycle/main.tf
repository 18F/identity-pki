variable "enabled" {
    default = 1
    description = "Whether this module is enabled (hack around modules not supporting count)"
}

variable "asg_name" {
    description = "Name of the auto scaling group to recycle"
}

variable "normal_desired_capacity" {
    description = ""
}

variable "max_size" {
    # in TF 0.10 you can leave this as the default
    default = -1
}

variable "min_size" {
    # in TF 0.10 you can leave this as the default
    default = -1
}

variable "spinup_mult_factor" {
    default = 2
    description = "Multiple of normal_desired_capacity to spin up"
}

# Spin up happens at   0500, 1100, 1700, 2300 UTC.
# Spin down happens at 0600, 1200, 1800, 0000 UTC.
#
# If IdP bootstrapping were faster (i.e. we reduce the ALB health check grace
# period time), we can reduce the interval between spinup and spindown.

# EST times (UTC-4):
# Spin up at   12a, 6a, 12p, 6p EST
# Spin down at  1a, 7a,  1p, 7p EST

# EDT times (UTC-5):
# Spin up at   1a, 7a, 1p, 7p EDT
# Spin down at 2a, 8a, 2p, 8p EDT

# PST times (UTC-7):
# Spin up at   3a, 9a,  3p, 9p  PST
# Spin down at 4a, 10a, 4p, 10p PST

# PDT times (UTC-8):
# Spin up at   4a, 10a, 4p, 10p PDT
# Spin down at 5a, 11a, 5p, 11p PDT

resource "aws_autoscaling_schedule" "spinup" {
    count = "${var.enabled}"

    scheduled_action_name  = "auto-recycle.spinup"
    min_size               = "${var.min_size}"
    max_size               = "${var.max_size}"
    desired_capacity       = "${var.normal_desired_capacity * var.spinup_mult_factor}"
    recurrence             = "0 5,11,17,23 * * *"
    autoscaling_group_name = "${var.asg_name}"
}

resource "aws_autoscaling_schedule" "spindown" {
    count = "${var.enabled}"

    scheduled_action_name  = "auto-recycle.spindown"
    min_size               = "${var.min_size}"
    max_size               = "${var.max_size}"
    desired_capacity       = "${var.normal_desired_capacity}"
    recurrence             = "0 0,6,12,18 * * *"

    autoscaling_group_name = "${var.asg_name}"
}
