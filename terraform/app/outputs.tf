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

output "elasticache" {
  value = {
    cluster_address           = aws_elasticache_replication_group.idp.primary_endpoint_address
    cluster_attempts_address  = aws_elasticache_replication_group.idp_attempts.primary_endpoint_address
    cluster_cache_address     = var.enable_redis_cache_instance ? aws_elasticache_replication_group.cache[0].primary_endpoint_address : aws_elasticache_replication_group.idp.primary_endpoint_address
    cluster_ratelimit_address = var.enable_redis_ratelimit_instance ? aws_elasticache_replication_group.ratelimit[0].primary_endpoint_address : aws_elasticache_replication_group.idp.primary_endpoint_address
  }
}

# AuroraDB

output "idp_aurora_from_rds" {
  value = var.idp_aurora_enabled ? {
    endpoint_reader          = module.idp_aurora_from_rds[0].reader_endpoint
    endpoint_writer          = module.idp_aurora_from_rds[0].writer_endpoint
    endpoint_writer_instance = module.idp_aurora_from_rds[0].writer_instance_endpoint
    fqdn_reader              = module.idp_aurora_from_rds[0].reader_fqdn
    fqdn_writer              = module.idp_aurora_from_rds[0].writer_fqdn
  } : null
}

output "dashboard_aurora_uw2" {
  value = var.apps_enabled == 1 ? {
    endpoint_reader          = module.dashboard_aurora_uw2[0].reader_endpoint
    endpoint_writer          = module.dashboard_aurora_uw2[0].writer_endpoint
    endpoint_writer_instance = module.dashboard_aurora_uw2[0].writer_instance_endpoint
    fqdn_reader              = module.dashboard_aurora_uw2[0].reader_fqdn
    fqdn_writer              = module.dashboard_aurora_uw2[0].writer_fqdn
  } : null
}

output "worker_aurora_uw2" {
  value = {
    endpoint_reader          = module.worker_aurora_uw2.reader_endpoint
    endpoint_writer          = module.worker_aurora_uw2.writer_endpoint
    endpoint_writer_instance = module.worker_aurora_uw2.writer_instance_endpoint
    fqdn_reader              = module.worker_aurora_uw2.reader_fqdn
    fqdn_writer              = module.worker_aurora_uw2.writer_fqdn
  }
}

#### misc / other

output "env_name" {
  value = var.env_name
}

output "region" {
  value = var.region
}
