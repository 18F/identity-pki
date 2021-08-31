module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=da46bc0d5442ac1b6403d48ed5d022aa88530e39"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on                  = [aws_config_configuration_recorder.default]
}
