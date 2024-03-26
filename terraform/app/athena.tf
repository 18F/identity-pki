module "athena_environment_database" {
  source       = "../modules/athena_database"
  env_name     = var.env_name
  region       = var.region
  apps_enabled = var.apps_enabled
  queries = [{
    name  = "Total Requests by HTTP Status Code"
    query = "SELECT status, COUNT(*) AS request_count FROM ${var.env_name}_cloudfront_logs GROUP BY status ORDER BY request_count DESC;"
    },
    {
      name  = "Top Requested URLs"
      query = "SELECT uri, COUNT(*) AS request_count FROM ${var.env_name}_cloudfront_logs GROUP BY uri ORDER BY request_count DESC;"
    },
    {
      name  = "Total Data Transferred"
      query = "SELECT SUM(bytes) AS total_bytes_sent FROM ${var.env_name}_cloudfront_logs;"
  }]

}

moved {
  from = aws_s3_bucket.athena_query_results
  to   = module.athena_environment_database.aws_s3_bucket.athena_query_results
}

moved {
  from = aws_s3_bucket_acl.athena_query_results
  to   = module.athena_environment_database.aws_s3_bucket_acl.athena_query_results
}

moved {
  from = aws_s3_bucket_ownership_controls.athena_query_results
  to   = module.athena_environment_database.aws_s3_bucket_ownership_controls.athena_query_results
}

moved {
  from = aws_s3_bucket_public_access_block.athena_query_results
  to   = module.athena_environment_database.aws_s3_bucket_public_access_block.athena_query_results
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.athena_query_results
  to   = module.athena_environment_database.aws_s3_bucket_server_side_encryption_configuration.athena_query_results
}

moved {
  from = module.athena_events_log_database.aws_athena_database.logs_database
  to   = module.athena_environment_database.aws_athena_database.logs_database
}
