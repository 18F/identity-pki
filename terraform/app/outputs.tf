#### IDP

output "idp_dashboard_arn" {
  value = module.idp_dashboard.dashboard_arn
}

# ALB

output "idp_alb" {
  value = {
    alb_hostname    = aws_alb.idp.dns_name
    ec2_sg_id       = aws_security_group.idp.id
    origin_dns_name = aws_route53_record.origin_alb_idp.fqdn
  }
}

# CloudFront

output "idp_cloudfront" {
  value = {
    domain_name = aws_route53_record.c_cloudfront_idp.fqdn
    custom_pages = [
      for k, v in var.cloudfront_custom_pages : (
        "https://${aws_route53_record.c_cloudfront_idp.fqdn}/${k}"
      )
    ]
    oai_arn  = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
    oai_path = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
  }
}

# RDS / ElastiCache

output "idp_rds" {
  value = var.idp_use_rds ? {
    rds_fqdn    = aws_route53_record.idp-postgres[0].fqdn
    db_endpoint = aws_db_instance.idp[0].endpoint
    db_endpoint_replica = (
      var.enable_rds_idp_read_replica ? aws_db_instance.idp-read-replica[0].endpoint : null
    )
    elasticache_cluster_address = (
      aws_elasticache_replication_group.idp.primary_endpoint_address
    )
    elasticache_cluster_attempts_address = (
      aws_elasticache_replication_group.idp_attempts.primary_endpoint_address
    )
  } : null
}

# AuroraDB

output "idp_aurora" {
  value = var.idp_aurora_enabled ? {
    endpoint_reader          = module.idp_aurora_from_rds[0].reader_endpoint
    endpoint_writer          = module.idp_aurora_from_rds[0].writer_endpoint
    endpoint_writer_instance = module.idp_aurora_from_rds[0].writer_instance_endpoint
    fqdn_reader              = module.idp_aurora_from_rds[0].reader_fqdn
    fqdn_writer              = module.idp_aurora_from_rds[0].writer_fqdn
  } : null
}

#### misc / other

output "app_rds" {
  value = var.apps_enabled == 1 ? {
    rds_fqdn     = aws_route53_record.postgres[0].fqdn
    rds_endpoint = aws_db_instance.default[0].endpoint
  } : null
}

output "idp_db_endpoint_worker_jobs" {
  value = aws_db_instance.idp-worker-jobs.endpoint
}

output "env_name" {
  value = var.env_name
}

output "region" {
  value = var.region
}
