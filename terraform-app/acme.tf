# Create the private key for the registration (not the certificate)
resource "tls_private_key" "acme_registration_private_key" {
  algorithm = "RSA"
}

# Set up a registration using a private key from tls_private_key
resource "acme_registration" "registration" {
  account_key_pem = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  email_address   = "developer@login.gov"
  server_url      = "https://acme-v01.api.letsencrypt.org/directory"
}

resource "acme_certificate" "dashboard" {
  account_key_pem           = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  common_name               = "dashboard.${var.env_name}.login.gov"
  count                     = "${var.apps_enabled == true ? 1 : 0}"
  registration_url          = "${acme_registration.registration.id}"
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"

  dns_challenge {
    provider = "route53"
  }

  # We need a new certificate before trying to delete the old one
  lifecycle {
      create_before_destroy = true
  }
}

resource "acme_certificate" "idp" {
  account_key_pem           = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  common_name               = "${var.env_name == "prod" ? "secure.login.gov" : format("%v.login.gov", var.env_name)}"

  # Disabled temporarily because our servers are not currently serving the stapled OCSP response as
  # part of the TLS handshake and this causes errors in Firefox
  must_staple               = false

  registration_url          = "${acme_registration.registration.id}"
  subject_alternative_names = ["idp.${var.env_name}.login.gov"]
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"

  # Modifying this at all forces a renwal due to https://github.com/paybyphone/terraform-provider-acme/issues/13
  min_days_remaining        = 14

  dns_challenge {
    provider = "route53"
  }

  # We need a new certificate before trying to delete the old one
  lifecycle {
      create_before_destroy = true
  }
}

resource "acme_certificate" "sp-oidc-sinatra" {
  account_key_pem           = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  common_name               = "sp-oidc-sinatra.${var.env_name}.login.gov"
  count                     = "${var.apps_enabled == true ? 1 : 0}"
  registration_url          = "${acme_registration.registration.id}"
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"

  dns_challenge {
    provider = "route53"
  }

  # We need a new certificate before trying to delete the old one
  lifecycle {
      create_before_destroy = true
  }
}

resource "acme_certificate" "sp-rails" {
  account_key_pem           = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  common_name               = "sp.${var.env_name}.login.gov"
  count                     = "${var.apps_enabled == true ? 1 : 0}"
  registration_url          = "${acme_registration.registration.id}"
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"
  subject_alternative_names = ["sp-rails.${var.env_name}.login.gov"]

  dns_challenge {
    provider = "route53"
  }

  # We need a new certificate before trying to delete the old one
  lifecycle {
      create_before_destroy = true
  }
}

resource "acme_certificate" "sp-sinatra" {
  account_key_pem           = "${tls_private_key.acme_registration_private_key.private_key_pem}"
  common_name               = "sp-sinatra.${var.env_name}.login.gov"
  count                     = "${var.apps_enabled == true ? 1 : 0}"
  registration_url          = "${acme_registration.registration.id}"
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"

  dns_challenge {
    provider = "route53"
  }

  # We need a new certificate before trying to delete the old one
  lifecycle {
      create_before_destroy = true
  }
}
