module "config_access_key_rotation" {
  source = "../../modules/config_access_key_rotation"

  config_access_key_rotation_name = var.config_access_key_rotation_name
  region                          = var.region
  config_access_key_rotation_code = "../../modules/config_access_key_rotation/${var.config_access_key_rotation_code}"
}