# frozen_string_literal: true

FactoryBot.define do
  factory :blacklisted_token do
    jti { SecureRandom.hex }
    user { create(:user) }
    exp { Time.now.utc + 1.hour }
  end
end
