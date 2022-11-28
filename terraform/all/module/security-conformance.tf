module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on = [aws_config_configuration_recorder.default]
}
