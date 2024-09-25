# manage Nessus Server resources (just Security Groups, for now);
# can add more regions upon approvals

module "nessus_server" {
  count  = var.manage_nessus_server ? 1 : 0
  source = "../../modules/nessus_server"
  providers = {
    aws = aws.usw2
  }

  rds_db_port = var.rds_db_port
}
