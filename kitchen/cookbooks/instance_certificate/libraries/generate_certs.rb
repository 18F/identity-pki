# This class helps generate new X509 certificates.
class Chef::Recipe::CertificateGenerator

  # Generate self signed key and certificate pair with the specified subject.
  #
  # @param subject [String] An X509 subject string, like "/C=US/CN=name/"
  # @param valid_days [Integer] Days before certificate expires
  #
  # @return [Array{OpenSSL::PKey::RSA, OpenSSL::X509::Certificate}] A pair of
  #   [key, cert].
  #
  def self.generate_selfsigned_keypair(subject, valid_days)
    key = OpenSSL::PKey::RSA.new(2048)
    public_key = key.public_key
    if subject.is_a?(OpenSSL::X509::Name)
      subject_name = subject
    else
      subject_name = OpenSSL::X509::Name.parse(subject)
    end

    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = subject_name
    cert.not_before = Time.now - 3600
    cert.not_after = Time.now + 24 * 60 * 60 * valid_days
    cert.public_key = public_key
    cert.serial = Random.rand(2**32-1) + 1
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension("basicConstraints","CA:FALSE", true),
      ef.create_extension("subjectKeyIdentifier", "hash"),
      ef.create_extension("keyUsage", "keyEncipherment,digitalSignature", true),
    ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                           "keyid:always,issuer:always")

    cert.sign key, OpenSSL::Digest::SHA256.new

    [key, cert]
  end
end
