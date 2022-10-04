locals {
  nginx_status_filters = {
    active_connections = {
      name         = "active_connections"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$active"
      unit         = "Count"
    },
    reading_connections = {
      name         = "reading_connections"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$reading"
      unit         = "Count"
    },
    writing_connections = {
      name         = "writing_connections"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$writing"
      unit         = "Count"
    },
    waiting_connections = {
      name         = "waiting_connections"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$waiting"
      unit         = "Count"
    },
    accepted_requests = {
      name         = "accepted_requests"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$accepts"
      unit         = "Count"
    },
    handled_requests = {
      name         = "handled_requests"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$handled"
      unit         = "Count"
    },
    total_requests = {
      name         = "total_requests"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$requests"
      unit         = "Count"
    },
    memory = {
      name         = "memory"
      pattern      = "[instance_id, autoscaling_group_name, instance_type, active, accepts, handled, requests, reading, writing, waiting, memory]"
      metric_value = "$memory"
      unit         = "Megabytes"
    }
  }

  passenger_status_filters = {
    active_client_count = {
      name         = "active_client_count"
      pattern      = "{$.active_client_count != -1}"
      metric_value = "$.active_client_count"
      unit         = "Count"
    },
    disconnected_client_count = {
      name         = "disconnected_client_count"
      pattern      = "{$.disconnected_client_count != -1}"
      metric_value = "$.disconnected_client_count"
      unit         = "Count"
    },
    free_client_count = {
      name         = "free_client_count"
      pattern      = "{$.free_client_count != -1}"
      metric_value = "$.free_client_count"
      unit         = "Count"
    },
    client_accept_speed = {
      name         = "client_accept_speed"
      pattern      = "{$.client_accept_speed != -1}"
      metric_value = "$.client_accept_speed"
      unit         = "Count"
    },
    request_begin_speed = {
      name         = "request_begin_speed"
      pattern      = "{$.request_begin_speed != -1}"
      metric_value = "$.request_begin_speed"
      unit         = "Count"
    },
    total_clients_accepted = {
      name         = "total_clients_accepted"
      pattern      = "{$.total_clients_accepted != -1}"
      metric_value = "$.total_clients_accepted"
      unit         = "Count"
    }
    total_requests_begun = {
      name         = "total_requests_begun"
      pattern      = "{$.total_requests_begun != -1}"
      metric_value = "$.total_requests_begun"
      unit         = "Count"
    }
    memory = {
      name         = "memory"
      pattern      = "{$.memory != -1}"
      metric_value = "$.memory"
      unit         = "Megabytes"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_asg" {
  for_each       = local.nginx_status_filters
  name           = "${each.value["name"]}_asg"
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.nginx_status.name
  metric_transformation {
    name      = "nginx_${each.value["name"]}"
    namespace = "${var.env_name}/nginx"
    value     = each.value["metric_value"]
    unit      = each.value["unit"]
    dimensions = {
      AutoscalingGroupName = "$autoscaling_group_name"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_instance" {
  for_each       = local.nginx_status_filters
  name           = "${each.value["name"]}_instance_type"
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.nginx_status.name
  metric_transformation {
    name      = "nginx_${each.value["name"]}"
    namespace = "${var.env_name}/nginx"
    value     = each.value["metric_value"]
    unit      = each.value["unit"]
    dimensions = {
      InstanceType         = "$instance_type"
      AutoscalingGroupName = "$autoscaling_group_name"
    }

  }
}

resource "aws_cloudwatch_log_metric_filter" "passenger_asg" {
  for_each       = local.passenger_status_filters
  name           = "${each.value["name"]}_asg"
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.passenger_status.name
  metric_transformation {
    name      = "passenger_${each.value["name"]}"
    namespace = "${var.env_name}/passenger"
    value     = each.value["metric_value"]
    unit      = each.value["unit"]
    dimensions = {
      AutoscalingGroupName = "$.autoscaling_group_name"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "passenger_instance" {
  for_each       = local.passenger_status_filters
  name           = "${each.value["name"]}_instance_type"
  pattern        = each.value["pattern"]
  log_group_name = aws_cloudwatch_log_group.passenger_status.name
  metric_transformation {
    name      = "passenger_${each.value["name"]}"
    namespace = "${var.env_name}/passenger"
    value     = each.value["metric_value"]
    unit      = each.value["unit"]
    dimensions = {
      InstanceType         = "$.instance_type"
      AutoscalingGroupName = "$.autoscaling_group_name"
    }

  }
}
