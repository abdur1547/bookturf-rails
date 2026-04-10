# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "User" }
    sequence(:last_name) { |n| "Name#{n}" }
    phone_number { "+92 300 1234567" }
    password { "password123" }
    password_confirmation { "password123" }
    is_active { true }
    is_global_admin { false }

    trait :with_google_oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-#{n}" }
      avatar_url { "https://example.com/avatar.jpg" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :global_admin do
      is_global_admin { true }
    end

    trait :with_emergency_contact do
      emergency_contact_name { "Emergency Contact" }
      emergency_contact_phone { "+92 300 9876543" }
    end
  end
end
