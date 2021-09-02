module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=8f0abe0e3708e2c1ef1c1653ae2b57b378bf8dbf"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on                  = [aws_config_configuration_recorder.default]
}
