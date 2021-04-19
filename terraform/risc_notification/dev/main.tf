provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["894947205914"] # require login-sandbox
  profile             = "identitysandbox.gov"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env_name = "dev"
  
  risc_notifications = {  
    dashboard = {
      partner_name            = "dashboard"
      notification_url        = "https://dashboard.dev.identitysandbox.gov/api/security_events"
      notification_rate_limit = 10
      notification_source     = "urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:dashboard"
      notification_state      = "ENABLED"
      basic_auth_user_name    = "na"
      api_key_name            = "x-api-key"
      authentication_type     = "API_KEY"
    }
  }
}