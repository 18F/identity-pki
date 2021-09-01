module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=af60fa023799d7f14c9f0f78ebaeb0bb6b2d7b5c"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on                  = [aws_config_configuration_recorder.default]
}
