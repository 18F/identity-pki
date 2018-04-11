FactoryBot.define do
  factory :certificate_revocation do
    certificate
    sequence(:serial, &:to_s)
  end
end
