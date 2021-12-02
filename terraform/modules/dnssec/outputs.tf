output "root_zone_dnssec_ksks" {
  description = "DNSSEC Key Signing Key information"

  value = tomap({
    for k, v in aws_route53_key_signing_key.dnssec : k => tomap({
      digest_algorithm  = v.digest_algorithm_mnemonic,
      digest_value      = v.digest_value,
      signing_algorithm = v.signing_algorithm_mnemonic,
      ds_record         = v.ds_record
    })
  })
}

output "active_ds_value" {
  description = "DS value for the KSK marked as active"

  # This mess pulls DS for the key with a value of "active".
  # If no keys in var.dnssec_ksks have a value of "active" it will fail
  value = aws_route53_key_signing_key.dnssec[[for k, v in var.dnssec_ksks : k if v == "active"][0]].ds_record
}

