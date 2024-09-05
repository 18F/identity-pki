module "cloudwatch_log_base_queries" {
  source   = "../modules/cloudwatch_log_queries"
  env_name = var.env_name
  region   = var.region
  db_types = {
    "idp" = "idp-uw2"
  }
}

resource "aws_cloudwatch_query_definition" "idp" {
  for_each = yamldecode(templatefile("cloudwatch-log-idp-queries.yml", { "env" = var.env_name, "region" = var.region }))

  name            = "${var.env_name}/${each.key}"
  log_group_names = each.value.logs
  query_string    = each.value.query
}


moved {
  from = aws_cloudwatch_query_definition.default["database/idp-postgresql-unusual-messages"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.db["database/idp-postgresql-unusual-messages"]
}

moved {
  from = aws_cloudwatch_query_definition.default["database/slow-queries/idp-postgresql-sharelock-waits"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.db["database/slow-queries/idp-postgresql-sharelock-waits"]
}

moved {
  from = aws_cloudwatch_query_definition.default["database/slow-queries/idp-postgresql-slow-queries"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.db["database/slow-queries/idp-postgresql-slow-queries"]
}

moved {
  from = aws_cloudwatch_query_definition.default["database/slow-queries/idp-postgresql-slow-queries-avg-max"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.db["database/slow-queries/idp-postgresql-slow-queries-avg-max"]
}

moved {
  from = aws_cloudwatch_query_definition.default["nginx/errors-by-source"]
  to   = aws_cloudwatch_query_definition.idp["nginx/errors-by-source"]
}

moved {
  from = aws_cloudwatch_query_definition.default["nginx/requests-by-ip"]
  to   = aws_cloudwatch_query_definition.idp["nginx/requests-by-ip"]
}

moved {
  from = aws_cloudwatch_query_definition.default["nginx/requests-by-ip-path"]
  to   = aws_cloudwatch_query_definition.idp["nginx/requests-by-ip-path"]
}

moved {
  from = aws_cloudwatch_query_definition.default["outboundproxy/allowed-requests-by-destination"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.obproxy["outboundproxy/allowed-requests-by-destination"]
}

moved {
  from = aws_cloudwatch_query_definition.default["outboundproxy/blocked-requests"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.obproxy["outboundproxy/blocked-requests"]
}

moved {
  from = aws_cloudwatch_query_definition.default["outboundproxy/blocked-requests-by-destination"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.obproxy["outboundproxy/blocked-requests-by-destination"]
}

moved {
  from = aws_cloudwatch_query_definition.default["pii/id-token-hint-use-by-redirect-uri"]
  to   = aws_cloudwatch_query_definition.idp["pii/id-token-hint-use-by-redirect-uri"]
}

moved {
  from = aws_cloudwatch_query_definition.default["pivcac/errors-by-issuer"]
  to   = aws_cloudwatch_query_definition.idp["pivcac/errors-by-issuer"]
}

moved {
  from = aws_cloudwatch_query_definition.default["pivcac/failures-by-service-provider"]
  to   = aws_cloudwatch_query_definition.idp["pivcac/failures-by-service-provider"]
}

moved {
  from = aws_cloudwatch_query_definition.default["provisioning/cloud-init-output"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.default["provisioning/cloud-init-output"]
}

moved {
  from = aws_cloudwatch_query_definition.default["rails/500s-by-controller"]
  to   = aws_cloudwatch_query_definition.idp["rails/500s-by-controller"]
}

moved {
  from = aws_cloudwatch_query_definition.default["rails/500s-by-path"]
  to   = aws_cloudwatch_query_definition.idp["rails/500s-by-path"]
}

moved {
  from = aws_cloudwatch_query_definition.default["saml/endpoint-year-by-referrer"]
  to   = aws_cloudwatch_query_definition.idp["saml/endpoint-year-by-referrer"]
}

moved {
  from = aws_cloudwatch_query_definition.default["saml/valid-endpoint-years-by-service-provider"]
  to   = aws_cloudwatch_query_definition.idp["saml/valid-endpoint-years-by-service-provider"]
}

moved {
  from = aws_cloudwatch_query_definition.default["ssm/aws-ssm-commands"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.ssm["ssm/aws-ssm-commands"]
}

moved {
  from = aws_cloudwatch_query_definition.default["ssm/aws-ssm-output"]
  to   = module.cloudwatch_log_base_queries.aws_cloudwatch_query_definition.ssm["ssm/aws-ssm-output"]
}

moved {
  from = aws_cloudwatch_query_definition.default["telephony/otp-phone-by-country"]
  to   = aws_cloudwatch_query_definition.idp["telephony/otp-phone-by-country"]
}

moved {
  from = aws_cloudwatch_query_definition.default["telephony/otp-setup-by-ip"]
  to   = aws_cloudwatch_query_definition.idp["telephony/otp-setup-by-ip"]
}

moved {
  from = aws_cloudwatch_query_definition.default["telephony/phone-setup-by-carrier-and-type"]
  to   = aws_cloudwatch_query_definition.idp["telephony/phone-setup-by-carrier-and-type"]
}

moved {
  from = aws_cloudwatch_query_definition.default["users/events-by-user_id"]
  to   = aws_cloudwatch_query_definition.idp["users/events-by-user_id"]
}

moved {
  from = aws_cloudwatch_query_definition.default["users/web-requests-by-user_id"]
  to   = aws_cloudwatch_query_definition.idp["users/web-requests-by-user_id"]
}

moved {
  from = aws_cloudwatch_query_definition.default["waf/blocked-by-path"]
  to   = aws_cloudwatch_query_definition.idp["waf/blocked-by-path"]
}

moved {
  from = aws_cloudwatch_query_definition.default["waf/blocked-by-rule-and-ip"]
  to   = aws_cloudwatch_query_definition.idp["waf/blocked-by-rule-and-ip"]
}

moved {
  from = aws_cloudwatch_query_definition.default["workers/failed_jobs"]
  to   = aws_cloudwatch_query_definition.idp["workers/failed_jobs"]
}
