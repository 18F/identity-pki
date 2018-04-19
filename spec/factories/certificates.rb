require 'securerandom'

FactoryBot.define do
  factory :certificate do
    key { SecureRandom.hex(20).gsub(/(..)/, '\\1:').chomp(':').upcase }
    sequence(:dn) { |n| "OU=testing CN=Certificate #{n}" }
    valid_not_before { Time.zone.now - 1.year }
    valid_not_after { Time.zone.now + 1.year }
  end
end
