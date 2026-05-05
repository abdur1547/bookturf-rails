# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "User full name #{n}" }
    sequence(:phone_number) { |n| "+92 30#{n % 10} 1234#{'%03d' % (n % 1000)}" }
    password { "password123" }
    password_confirmation { "password123" }
    is_active { true }
    system_role { :normal }

    trait :with_google_oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-#{n}" }
      avatar_url { "https://example.com/avatar.jpg" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :super_admin do
      system_role { :super_admin }
    end

    trait :with_emergency_contact do
      emergency_contact_name { "Emergency Contact" }
      emergency_contact_phone { "+92 300 9876543" }
    end
  end
end
