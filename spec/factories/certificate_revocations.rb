FactoryBot.define do
  factory :certificate_revocation do
    certificate_authority
    sequence(:serial, &:to_s)
  end
end
