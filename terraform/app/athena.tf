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
