# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    token { SecureRandom.hex }
    crypted_token { Digest::SHA256.hexdigest(token) }
    user { create(:user) }
    exp { Time.now.utc }
  end
end
