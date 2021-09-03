module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=fe5cedbab370a69079261adb5e0ff1f7cd51acf8"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on                  = [aws_config_configuration_recorder.default]
}
