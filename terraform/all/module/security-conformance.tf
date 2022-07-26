module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=5d344d205dd09eb85d5de1ff1081c4a598afe433"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on = [aws_config_configuration_recorder.default]
}
