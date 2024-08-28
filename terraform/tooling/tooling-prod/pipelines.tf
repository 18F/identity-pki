# Set up global config for codebuild/pipeline
module "main" {
  source = "../module"
  region = "us-west-2"
  # The domain we put this stuff under
  dns_domain = "gitlab.login.gov"
}