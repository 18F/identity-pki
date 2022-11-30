locals {
  idp_uri_denylist_filter = join(" && ",
    concat(
      # Only ignore "GET /", not "POST /", which is used for email/password submission
      ["$.request != \"GET / HTTP/1.1\""],
      formatlist("$.uri_path != \"%s\"", var.sli_uninteresting_uris)
    )
  )
}

resource "aws_cloudwatch_log_metric_filter" "idp_interesting_uris_success" {
  name           = "${var.env_name}-idp-interesting-uris-success"
  log_group_name = "${var.env_name}_/var/log/nginx/access.log"
  pattern        = join("", ["{", local.idp_uri_denylist_filter, " && $.status != 5*}"])
  metric_transformation {
    name      = "InterestingUrisSuccess"
    namespace = "${var.env_name}/sli"
    value     = 1
    dimensions = {
      Hostname = "$.hostname"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "idp_interesting_uris_total" {
  name           = "${var.env_name}-idp-interesting-uris-total"
  log_group_name = "${var.env_name}_/var/log/nginx/access.log"
  pattern        = join("", ["{", local.idp_uri_denylist_filter, "}"])
  metric_transformation {
    name      = "InterestingUrisTotal"
    namespace = "${var.env_name}/sli"
    value     = 1
    dimensions = {
      Hostname = "$.hostname"
    }
  }
}

module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
  # TODO: pass the SLI definitions in to the module
  # TODO: pass custom metric definitions in to the module
}
