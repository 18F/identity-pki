module "log-ship-s3-soc" {
  source                              = "../modules/log_ship_s3_soc"
  region                              = "us-west-2"
  cloudwatch_subscription_filter_name = "log-ship"
  cloudwatch_log_group_name           = {
                                        CloudTrail/DefaultLogGroup = " "
                                    }   
  env_name                            = "account"
  soc_destination_arn                 = "arn:aws:logs:us-west-2:752281881774:destination:elp-cloudtrail-lg"
}
