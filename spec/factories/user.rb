# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_google_oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-#{n}" }
      avatar_url { "https://example.com/avatar.jpg" }
    end

    trait :with_tracking do
      sign_in_count { 5 }
      current_sign_in_at { 1.hour.ago }
      last_sign_in_at { 1.day.ago }
      current_sign_in_ip { "192.168.1.1" }
      last_sign_in_ip { "192.168.1.2" }
    end
  end
end
