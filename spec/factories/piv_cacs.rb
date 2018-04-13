require 'securerandom'

FactoryBot.define do
  factory :piv_cac do
    sequence(:dn) { |n| "DC=com, DC=example, CN=User #{n}" }
  end
end
