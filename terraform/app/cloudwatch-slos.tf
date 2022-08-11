module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=7505e64eb3bc5013d32007bd49acfeea7b78d25d"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
