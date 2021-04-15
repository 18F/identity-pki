require 'rails_helper'

RSpec.describe TokenService do
  let(:token_service) { described_class }

  let(:data) { { 'a' => 'b' } }

  it 'opens a boxed value' do
    expect(token_service.open(token_service.box(data))).to eq data
  end

  it 'can open with data encrypted by old key' do
    old_salt = IdentityConfig.store.token_encryption_key_salt_old
    old_pepper = IdentityConfig.store.token_encryption_key_pepper_old

    key = ActiveSupport::KeyGenerator.new(old_pepper).generate_key(old_salt, 32)
    old_encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')
    data_encypted_with_old_encryptor = TokenService.box(data, old_encryptor)

    expect(token_service.open(data_encypted_with_old_encryptor)).to eq data
  end
end
