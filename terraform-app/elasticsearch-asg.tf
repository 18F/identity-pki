module "elasticsearch_user_data" {
  source = "../terraform-modules/bootstrap/"

  role = "elasticsearch"
  env = "${var.env_name}"
  domain = "${var.root_domain}"

  chef_download_url = "${var.chef_download_url}"
  chef_download_sha256 = "${var.chef_download_sha256}"

  # identity-devops-private variables
  private_s3_ssh_key_url = "${local.bootstrap_private_s3_ssh_key_url}"
  private_git_clone_url = "${var.bootstrap_private_git_clone_url}"
  private_git_ref = "${var.bootstrap_private_git_ref}"

  # identity-devops variables
  main_s3_ssh_key_url = "${local.bootstrap_main_s3_ssh_key_url}"
  main_git_clone_url = "${var.bootstrap_main_git_clone_url}"
  main_git_ref_map = "${var.bootstrap_main_git_ref_map}"
  main_git_ref_default = "${local.bootstrap_main_git_ref_default}"

  # proxy variables
  proxy_server = "${var.proxy_server}"
  proxy_port = "${var.proxy_port}"
  no_proxy_hosts = "${var.no_proxy_hosts}"
  proxy_enabled_roles = "${var.proxy_enabled_roles}"
}

module "elasticsearch_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=774195a363107e0d9b4aa658a30dad2a78efcb56"

  role           = "elasticsearch"
  env            = "${var.env_name}"
  root_domain    = "${var.root_domain}"
  ami_id_map     = "${var.ami_id_map}"
  default_ami_id = "${local.account_default_ami_id}"

  instance_type             = "${var.instance_type_es}"
  iam_instance_profile_name = "${aws_iam_instance_profile.elasticsearch.name}"
  security_group_ids        = ["${aws_security_group.elk.id}", "${aws_security_group.base.id}"] # TODO elasticsearch should not use elk security group

  user_data                 = "${module.elasticsearch_user_data.rendered_cloudinit_config}"

  template_tags = {
    main_git_ref = "${module.elasticsearch_user_data.main_git_ref}"
  }

  block_device_mappings = [
    {
      device_name = "/dev/sdg"
      ebs = [
        {
          volume_size = "${var.elasticsearch_volume_size}"
          volume_type = "gp2"
          encrypted = true
        }
      ]
    }
  ]
}

module "elasticsearch_lifecycle_hooks" {
  source = "github.com/18F/identity-terraform//asg_lifecycle_notifications?ref=2c43bfd79a8a2377657bc8ed4764c3321c0f8e80"
  asg_name = "${aws_autoscaling_group.elasticsearch.name}"
}

resource "aws_autoscaling_group" "elasticsearch" {
    name = "${var.env_name}-elasticsearch"

    launch_template = {
      id = "${module.elasticsearch_launch_template.template_id}"
      version = "$$Latest"
    }

    min_size = 0
    max_size = 32
    desired_capacity = "${var.asg_elasticsearch_desired}"

    wait_for_capacity_timeout = 0

    vpc_zone_identifier = ["${aws_subnet.elasticsearch.*.id}"]

    # https://github.com/18F/identity-devops-private/issues/631
    health_check_type = "EC2"
    health_check_grace_period = 0

    termination_policies = ["OldestInstance"]

    load_balancers = []
    target_group_arns = ["${aws_lb_target_group.elasticsearch.arn}"]

    # Because these nodes have persistent data, we terminate manually.
    protect_from_scale_in = true

    # tags on the instance will come from the launch template
    tag {
        key = "prefix"
        value = "elasticsearch"
        propagate_at_launch = false
    }
    tag {
        key = "domain"
        value = "${var.env_name}.${var.root_domain}"
        propagate_at_launch = false
    }

    # elasticsearch instances are stateful, shouldn't be recycled willy nilly
    tag {
        key = "stateful"
        value = "true"
        propagate_at_launch = true
    }
}

data "aws_iam_policy_document" "elasticsearch_asg_role_policy" {
  # Allow notifying ASG lifecycle hooks. This isn't a great place for this
  # permission since not actually related, but it's useful to put here because
  # all of our ASG instances need it.
  statement {
    sid = "AllowCompleteLifecycleHook"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat"
    ]
    resources = [
      "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
    ]
  }
}
