module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=a6261020a94b77b08eedf92a068832f21723f7a2"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on = [aws_config_configuration_recorder.default]
}
