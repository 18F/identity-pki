output "root_zone_dnssec_ksks" {
  description = "DNSSEC Key Signing Key information"

  value = tomap({
    for k, v in aws_route53_key_signing_key.primary : k => tomap({
      digest_algorithm  = v.digest_algorithm_mnemonic,
      digest_value      = v.digest_value,
      signing_algorithm = v.signing_algorithm_mnemonic,
      ds_record         = v.ds_record
    })
  })
}
