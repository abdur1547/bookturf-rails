# frozen_string_literal: true

FactoryBot.define do
  factory :venue do
    association :owner, factory: :user

    sequence(:name) { |n| "Sports Arena #{n}" }
    sequence(:slug) { |n| "sports-arena-#{n}" }
    description { "Premier sports facility with multiple courts" }
    address { "Plot 123, Block 5, Clifton" }
    city { "Karachi" }
    state { "Sindh" }
    country { "Pakistan" }
    postal_code { "75600" }
    latitude { 24.8175 }
    longitude { 67.0297 }
    phone_number { "+92 21 35123456" }
    email { "info@sportsarena.pk" }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :without_coordinates do
      latitude { nil }
      longitude { nil }
    end

    trait :with_setting do
      after(:create) do |venue|
        create(:venue_setting, venue: venue) unless venue.venue_setting.present?
      end
    end

    trait :with_operating_hours do
      after(:create) do |venue|
        if venue.venue_operating_hours.empty?
          (0..6).each do |day|
            create(:venue_operating_hour, venue: venue, day_of_week: day)
          end
        end
      end
    end

    # Since venue auto-creates settings and hours, we can skip the callbacks for testing
    trait :skip_callbacks do
      after(:build) do |venue|
        venue.define_singleton_method(:create_default_settings) { }
        venue.define_singleton_method(:create_default_operating_hours) { }
      end
    end
  end
end
