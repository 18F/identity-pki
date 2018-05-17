require 'securerandom'

FactoryBot.define do
  factory :unrecognized_certificate_authority do
    key { SecureRandom.hex(20).gsub(/(..)/, '\\1:').chomp(':').upcase }
    sequence(:dn) { |n| "O=Unseen University, OU=testing CN=Certificate #{n}" }
  end
end
