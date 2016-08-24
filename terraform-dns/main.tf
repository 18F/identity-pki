provider "aws" {
  access_key = "${var.access_key_18f_ent}"
  secret_key = "${var.secret_key_18f_ent}"
  region = "${var.region}"
  profile = "18f-ent"
}

provider "aws" {
  access_key = "${var.access_key}"
  alias = "18f-sandbox"
  profile = "18f-sandbox"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}
