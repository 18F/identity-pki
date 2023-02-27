module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on = [aws_config_configuration_recorder.default]
}
