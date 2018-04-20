require 'base64'
require 'openssl'
require 'securerandom'

class PivCac < ApplicationRecord
  DN_SIGNATURE_HASH = 'SHA512'.freeze

  before_validation :create_uuid, on: :create

  validates :dn_signature, presence: true, uniqueness: true, case_sensitive: false
  validates :uuid, presence: true, uniqueness: true, case_sensitive: false

  def dn=(raw)
    self.dn_signature = PivCac.make_dn_signature(raw)
  end

  class << self
    def find_or_create_by(opts = {})
      dn = opts[:dn]
      if dn
        super(opts.except(:dn).merge(dn_signature: make_dn_signature(dn)))
      else
        super
      end
    end

    def find_by(opts = {})
      dn = opts[:dn]
      if dn
        super(opts.except(:dn).merge(dn_signature: make_dn_signature(dn)))
      else
        super
      end
    end

    def make_dn_signature(raw)
      Base64.encode64(OpenSSL::Digest.digest(DN_SIGNATURE_HASH, raw)).chomp if raw
    end
  end

  private

  def create_uuid
    self.uuid = SecureRandom.uuid unless uuid
  end
end
