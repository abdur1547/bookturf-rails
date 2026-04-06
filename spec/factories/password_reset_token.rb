# frozen_string_literal: true

FactoryBot.define do
  factory :password_reset_token do
    user
    otp_code_digest { Digest::SHA256.hexdigest("123456") }
    expires_at { 15.minutes.from_now }
    used_at { nil }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :used do
      used_at { 1.hour.ago }
    end

    trait :valid do
      expires_at { 15.minutes.from_now }
      used_at { nil }
    end
  end
end
